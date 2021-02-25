#------------------------------------------------------------------------------
# Collect necessary data
#------------------------------------------------------------------------------
data "aws_ami" "latest_ecs_ami" {
  most_recent = true
  owners      = ["591542846629"] # AWS
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2*-x86_64-ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
  vars = {
    ecs_cluster_name = var.ecs_name
    efs_id           = var.efs_id
    http_proxy       = var.http_proxy
    http_proxy_port  = var.http_proxy_port
    system_controls  = join("\n", data.template_file.sysctl.*.rendered)
  }
}

data "template_file" "sysctl" {
  count    = length(var.system_controls)
  template = file("${path.module}/system_controls.tpl")
  vars = {
    key   = var.system_controls[count.index].name
    value = var.system_controls[count.index].value
  }
}

data "template_cloudinit_config" "this" {
  base64_encode = true
  gzip          = false

  part {
    filename     = "common.script"
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data.rendered
  }
}


#------------------------------------------------------------------------------
# Local Values
#------------------------------------------------------------------------------
locals {
  tags_asg_format = null_resource.tags_as_list_of_maps.*.triggers
}

resource "null_resource" "tags_as_list_of_maps" {
  count = length(keys(var.tags))

  triggers = {
    "key"                 = keys(var.tags)[count.index]
    "value"               = values(var.tags)[count.index]
    "propagate_at_launch" = "true"
  }
}

#DBG user_data, might be useful to keep representation in state for reference.
resource "null_resource" "user_data_rendered_view" {
  triggers = {
    user_data = data.template_file.user_data.rendered
  }
}

#------------------------------------------------------------------------------
# Create ECS Cluster
#------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = var.ecs_name
  description = "Security Group for ECS cluster"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = var.ecs_cidr_block
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    {
      "Name" = var.ecs_name
    },
    var.tags
  )
}

resource "aws_ecs_cluster" "this" {
  name               = var.ecs_name
  capacity_providers = [aws_ecs_capacity_provider.this.name]
  tags = merge(
    {
      "Name" = var.ecs_name
    },
    var.tags
  )
  depends_on = [aws_ecs_capacity_provider.this]
}

##NB: https://github.com/hashicorp/terraform-provider-aws/issues/4852
## The Cluster cannot be deleted/renamed while Container Instances are active or draining.
resource "null_resource" "asg-scale-to-0-on-destroy" {
  triggers = {
    cluster_arn            = aws_ecs_cluster.this.arn
    capacity_providers_arn = join(",", aws_ecs_cluster.this.capacity_providers)
    asg_name               = aws_autoscaling_group.this.name
  }
  provisioner "local-exec" {
    when    = destroy
    command = "aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${self.triggers.asg_name} --min-size 0 --max-size 0 --desired-capacity 0"
  }
  depends_on = [aws_ecs_cluster.this]
}

resource "aws_autoscaling_group" "this" {
  name                      = var.ecs_name
  min_size                  = var.ecs_min_size
  max_size                  = var.ecs_max_size
  desired_capacity          = var.ecs_desired_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = var.subnet_ids

  launch_template {
    id      = "${aws_launch_template.this.id}"
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = concat(
    [
      {
        key                 = "Name"
        value               = var.ecs_name
        propagate_at_launch = true
      }
    ],
    local.tags_asg_format,
  )
}

resource "aws_ecs_capacity_provider" "this" {
  name = "${var.ecs_name}-capacity"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = var.ecs_capacity_provider_target
    }
  }
  depends_on = [aws_autoscaling_group.this]
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.ecs_name}-"
  image_id      = data.aws_ami.latest_ecs_ami.image_id
  instance_type = var.ecs_instance_type
  key_name      = var.ecs_key_name
  vpc_security_group_ids = (length(var.efs_sg_ids) > 0 ? concat([
    aws_security_group.this.id], var.efs_sg_ids) : [
  aws_security_group.this.id])

  user_data = data.template_cloudinit_config.this.rendered

  network_interfaces {
    associate_public_ip_address = var.ecs_associate_public_ip_address
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  monitoring {
    enabled = var.monitoring
  }

  metadata_options {
    http_endpoint               = var.metadata_options_endpoint
    http_tokens                 = var.metadata_options_tokens
    http_put_response_hop_limit = var.metadata_options_hop_limit
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      {
        "Name" = var.ecs_name
      },
      var.tags
    )
  }
}

#------------------------------------------------------------------------------
# Create the Instance Profile
#------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "this" {
  name = var.ecs_name
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name               = var.ecs_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge(
    {
      "Name" = var.ecs_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "this" {
  name   = var.ecs_name
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.policy.json
}


resource "aws_iam_role_policy_attachment" "additional_instance_role_policy" {
  role       = aws_iam_role.this.name
  policy_arn = var.additional_instance_role_policy
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:ListContainerInstances",
      "ecs:DescribeContainerInstances",
      "ecs:Submit*",
      "ecs:StartTask",
      "ecs:ListClusters",
      "ecs:DescribeClusters",
      "ecs:RegisterTaskDefinition",
      "ecs:RunTask",
      "ecs:StopTask",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = var.ecs_additional_iam_statements
    content {
      effect    = lookup(statement.value, "effect", null)
      actions   = lookup(statement.value, "actions", null)
      resources = lookup(statement.value, "resources", null)
    }
  }

}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs.amazonaws.com",
        "ec2.amazonaws.com"
      ]
    }
  }
}
