#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------
output "cluster_id" {
  description = "Cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "Cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_asg_name" {
  description = "Cluster AutoScaling Group Name"
  value       = aws_autoscaling_group.this.name
}

output "cluster_asg_arn" {
  description = "Cluster AutoScaling Group ARN"
  value       = aws_autoscaling_group.this.arn
}

output "cluster_iam_role_arn" {
  description = "Cluster IAM role ARN"
  value       = aws_iam_role.this.arn
}

output "cluster_aws_launch_configuration_name" {
  description = "Cluster AutoScaling Group aws_launch_configuration Name"
  value       = aws_launch_configuration.this.name
}