output "cluster_profile_arn" {
    value = aws_iam_instance_profile.cluster_profile.arn
}

output "emr_service_arn" {
    value = aws_iam_role.emr_service_role.arn
}