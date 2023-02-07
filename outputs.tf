#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------
output "cluster_id" {
  description = "Cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "Cluster ARN"
  value       = local.asg.arn
}

output "cluster_asg_name" {
  description = "Cluster AutoScaling Group Name"
  value       = local.asg.name
}

output "cluster_asg_arn" {
  description = "Cluster AutoScaling Group ARN"
  value       = local.asg.arn
}

output "cluster_iam_role_arn" {
  description = "Cluster IAM role ARN"
  value       = aws_iam_role.this.arn
}

output "cluster_aws_launch_template_name" {
  description = "Cluster AutoScaling Group aws_template Name"
  value       = aws_launch_template.this.name
}

output "cluster_security_group_id" {
  description = "ID from the security group for the ECS cluster"
  value       = aws_security_group.this.id
}