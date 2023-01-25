#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------
variable "depends_on_efs" {
  description = "If attaching EFS, it makes sure that the mount targets are ready"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "The VPC ID that the cluster will be deployed to"
  type        = string
}

variable "subnet_ids" {
  description = "The Subnet IDs"
  type        = list(string)
}

variable "attach_efs" {
  description = "Whether to try and attach an EFS volume to the instances"
  type        = bool
  default     = false
}

variable "efs_sg_ids" {
  description = "The EFS Security Group ID(s)"
  type        = list(string)
  default     = [""]
}

variable "efs_id" {
  description = "The EFS ID - Required if attach_efs is true"
  type        = string
  default     = ""
}

variable "ecs_name" {
  description = "ECS Cluster Name"
  type        = string
}

variable "ecs_cidr_block" {
  description = "ECS CIDR block"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "ecs_min_size" {
  description = "Minimum number of EC2 instances."
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of EC2 instances."
  type        = number
  default     = 1
}

variable "ecs_desired_capacity" {
  description = "Desired number of EC2 instances."
  type        = number
  default     = 1
}

variable "ecs_instance_type" {
  description = "Default instance type"
  type        = string
  default     = "t3.medium"
}

variable "ecs_volume_size" {
  description = "Default instance root volume size"
  type        = string
  default     = "30"
}

variable "ecs_volume_type" {
  description = "Default instance root volume type"
  type        = string
  default     = "gp2"
}

variable "ecs_key_name" {
  description = "SSH key name in your AWS account for AWS instances."
  type        = string
  default     = ""
}

variable "ecs_associate_public_ip_address" {
  description = "Whether to associate a public IP in the launch configuration"
  type        = bool
  default     = false
}

variable "ecs_additional_iam_statements" {
  description = "Additional IAM statements for the ECS instances"
  type        = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "ecs_capacity_provider_target" {
  description = "Percentage target of capacity to get to before triggering scaling"
  type        = number
  default     = 90
}

variable "http_proxy" {
  description = "Name of the HTTP proxy on the network"
  type        = string
  default     = ""
}

variable "http_proxy_port" {
  description = "Port number of the HTTP proxy"
  type        = number
  default     = 3128
}

variable "monitoring" {
  description = "Enabling detailed monitoring for launch template instances"
  default     = "true"
}

variable "metadata_options_endpoint" {
  description = "Metadata option http endpoint"
  default     = "enabled"
}
variable "metadata_options_tokens" {
  description = "Metadata option http tokens"
  default     = "required"
}
variable "metadata_options_hop_limit" {
  description = "Metadata option http hop limit"
  type        = number
  default     = 1
}

variable "additional_instance_role_policy" {
  description = "Additional policy that can be added to the ECS instances. By default we have SSM access enabled"
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

variable "asg_protect_from_scale_in" {
  description = <<-EOT
  Allows setting instance protection. The Auto Scaling Group will not select instances with this setting
  for termination during scale in events.
  EOT
  type        = bool
  default     = true
}

variable "asg_provider_managed_termination_protection" {
  description = <<-EOT
  Enables or disables container-aware termination of instances in the auto scaling group when scale-in happens.
  Valid values are ENABLED and DISABLED.
  EOT
  type        = string
  default     = "ENABLED"
}

variable "ecs_wait_for_capacity_timeout" {
  description = "ASG creation wait timeout"
  type        = string
  default     = "20m"
}

variable "ecs_engine_task_cleanup_wait_duration" {
  description = <<-EOT
  Time to wait from when a task is stopped until the Docker container is removed. As this removes the Docker container
  data, be aware that if this value is set too low, you may not be able to inspect your stopped containers or view the
  logs before they are removed. The minimum duration is 1m; any value shorter than 1 minute is ignored.
  EOT
  type        = string
  default     = "3h"
}

variable "instance_types" {
  description = "Instance types to launch, minimum 2 types must be specified. List of Map of 'instance_type'(required) and 'weighted_capacity'(optional)."
  type        = list(object({
    instance_type     = string
    weighted_capacity = number
  }))
  default = []
}