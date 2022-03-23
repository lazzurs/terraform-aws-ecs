# AWS ECS Terraform Module
Terraform module that deploys an ECS autoscaling group.  If you include an EFS ID and EFS Security Group, it will also 
mount the EFS volume to the ECS instances.  

# HTTP Proxy support
In some environments an HTTP proxy will be required to get containers and talk to the outside world. This module 
supports this via the http_proxy and http_proxy_port variables.

# Deploying with EFS
By default, the module will deploy without trying to mount an EFS volume.

There are two modes of using EFS with this module, either using EFS as a mounted file system on the hosts or as volumes
for the containers.

If using EFS as volumes in the containers you will need to provide the security groups used for the EFS volumes.

If using EFS as a mounted filesystem and you attempt to deploy the EFS at the same time as the ECS cluster, a race 
condition exists where the autoscaling group gets created before the mount targets have finished being created.   To 
avoid this, you can set the depends_on_efs variable to the aws_efs_mount_target output.  This way, the autoscaling 
group won't get created until the EFS mount targets have been created.

## Usage

This example is showing using EFS as a mounted filesystem on the hosts.

```hcl
module "ecs-0" {
  source                        = "lazzurs/ecs/aws"
  version                       = "1.1.0"
  ecs_name                      = "my-ecs-cluster"
  vpc_id                        = vpc-0e151a59f874eadd8
  ecs_cidr_block                = ["10.0.0.0/8"]
  subnet_ids                    = ["subnet-1e151a59f874eadd8", "subnet-0e148a59f874eadd8", "subnet-2e151a57f874eadd8"]
  ecs_min_size                  = "1"
  ecs_max_size                  = "3"
  ecs_desired_capacity          = "2"
  ecs_instance_type             = "t2.large"
  ecs_key_name                  = "aws-key"
  tags                          = var.tags
  ecs_additional_iam_statements = var.ecs_additional_iam_statements
  attach_efs                    = true
  efs_id                        = "fs-532cdcd3"
  efs_sg_id                     = "sg-076487b693f21bcb8"
  depends_on_efs                = ["fsmt-8387e72b"]
}
# Variables
tags = {
         Terraform = "true"
         Environment = "development"
       }

ecs_additional_iam_statements = [
  {
    effect = "Allow"
    actions = [
      "ec2:*",
      "autoscaling:*"
    ]
    resources = ["*"]
  }
]

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | >= 2.45 |

## Providers

| Name | Version |
|------|---------|
| aws | 4.3.0 |
| null | 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ecs_capacity_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.additional_instance_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [null_resource.asg-scale-to-0-on-destroy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.tags_as_list_of_maps](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssm_parameter.ecs_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_instance\_role\_policy | Additional policy that can be added to the ECS instances. By default we have SSM access enabled | `string` | `"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"` | no |
| asg\_protect\_from\_scale\_in | Allows setting instance protection. The Auto Scaling Group will not select instances with this setting for termination during scale in events. | `bool` | `true` | no |
| asg\_provider\_managed\_termination\_protection | Enables or disables container-aware termination of instances in the auto scaling group when scale-in happens. Valid values are ENABLED and DISABLED. | `string` | `"ENABLED"` | no |
| attach\_efs | Whether to try and attach an EFS volume to the instances | `bool` | `false` | no |
| depends\_on\_efs | If attaching EFS, it makes sure that the mount targets are ready | `list(string)` | `[]` | no |
| ecs\_additional\_iam\_statements | Additional IAM statements for the ECS instances | ```list(object({ effect = string actions = list(string) resources = list(string) }))``` | `[]` | no |
| ecs\_associate\_public\_ip\_address | Whether to associate a public IP in the launch configuration | `bool` | `false` | no |
| ecs\_capacity\_provider\_target | Percentage target of capacity to get to before triggering scaling | `number` | `90` | no |
| ecs\_cidr\_block | ECS CIDR block | `list(string)` | n/a | yes |
| ecs\_desired\_capacity | Desired number of EC2 instances. | `number` | `1` | no |
| ecs\_engine\_task\_cleanup\_wait\_duration | Time to wait from when a task is stopped until the Docker container is removed. As this removes the Docker container data, be aware that if this value is set too low, you may not be able to inspect your stopped containers or view the logs before they are removed. The minimum duration is 1m; any value shorter than 1 minute is ignored. | `string` | `"3h"` | no |
| ecs\_instance\_type | Default instance type | `string` | `"t3.medium"` | no |
| ecs\_key\_name | SSH key name in your AWS account for AWS instances. | `string` | `""` | no |
| ecs\_max\_size | Maximum number of EC2 instances. | `number` | `1` | no |
| ecs\_min\_size | Minimum number of EC2 instances. | `number` | `1` | no |
| ecs\_name | ECS Cluster Name | `string` | n/a | yes |
| ecs\_volume\_size | Default instance root volume size | `string` | `"30"` | no |
| ecs\_volume\_type | Default instance root volume type | `string` | `"gp2"` | no |
| ecs\_wait\_for\_capacity\_timeout | ASG creation wait timeout | `string` | `"20m"` | no |
| efs\_id | The EFS ID - Required if attach\_efs is true | `string` | `""` | no |
| efs\_sg\_ids | The EFS Security Group ID(s) | `list(string)` | ```[ "" ]``` | no |
| http\_proxy | Name of the HTTP proxy on the network | `string` | `""` | no |
| http\_proxy\_port | Port number of the HTTP proxy | `number` | `3128` | no |
| metadata\_options\_endpoint | Metadata option http endpoint | `string` | `"enabled"` | no |
| metadata\_options\_hop\_limit | Metadata option http hop limit | `number` | `1` | no |
| metadata\_options\_tokens | Metadata option http tokens | `string` | `"required"` | no |
| monitoring | Enabling detailed monitoring for launch template instances | `string` | `"true"` | no |
| subnet\_ids | The Subnet IDs | `list(string)` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| vpc\_id | The VPC ID that the cluster will be deployed to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_arn | Cluster ARN |
| cluster\_asg\_arn | Cluster AutoScaling Group ARN |
| cluster\_asg\_name | Cluster AutoScaling Group Name |
| cluster\_aws\_launch\_template\_name | Cluster AutoScaling Group aws\_template Name |
| cluster\_iam\_role\_arn | Cluster IAM role ARN |
| cluster\_id | Cluster ID |
| cluster\_security\_group\_id | ID from the security group for the ECS cluster |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors
Module has been forked from a module by [Mark Honomichl](https://github.com/austincloudguru).
Maintained by Rob Lazzurs.

## License
MIT Licensed.  See LICENSE for full details
