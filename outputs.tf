#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------
output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "cluster_asg_name" {
  value = aws_autoscaling_group.this.name
}

output "cluster_asg_arn" {
  value = aws_autoscaling_group.this.arn
}

output "cluster_iam_role_arn" {
  value = aws_iam_role.this.arn
}