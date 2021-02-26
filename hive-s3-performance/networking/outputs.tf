output "cluster_vpc_id" {
  value = aws_vpc.cluster_vpc.id
}

output "cluster_subnet_id" {
  value = aws_subnet.cluster_subnet.id
}

output "backup_subnet_id" {
  value = aws_subnet.backup_subnet.id
}

output "master_security_group" {
  value = aws_security_group.master_security_group.id
}

output "core_security_group" {
  value = aws_security_group.core_security_group.id
}

output "load_balancer_security_group" {
  value = aws_security_group.lb_security_group.id
}