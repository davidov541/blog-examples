resource "aws_vpc" "cluster_vpc" {
	cidr_block           = "10.0.0.0/16"
	enable_dns_hostnames = true

	tags = {
		Name = "Hive-S3 Performance Test VPC"
	}
}

resource "aws_internet_gateway" "cluster_internet_gateway" {
	vpc_id = aws_vpc.cluster_vpc.id

	tags = {
		Name = "Hive-S3 Performance Test Internet Gateway"
	}
}

resource "aws_subnet" "cluster_subnet" {
	vpc_id            = aws_vpc.cluster_vpc.id
	cidr_block        = "10.0.1.0/24"
	availability_zone = "us-east-2a"

	tags = {
		Name = "Hive-S3 Performance Test Subnet"
	}
}

resource "aws_subnet" "backup_subnet" {
	vpc_id            = aws_vpc.cluster_vpc.id
	cidr_block        = "10.0.2.0/24"
	availability_zone = "us-east-2b"

	tags = {
		Name = "Hive-S3 Performance Test Backup Subnet"
	}
}

resource "aws_route_table" "cluster_route_table" {
	vpc_id = aws_vpc.cluster_vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.cluster_internet_gateway.id
	}
	tags = {
		Name = "Hive-S3 Performance Test Route Table"
	}
}

resource "aws_route_table_association" "cluster_subnet_route_table_association" {
	subnet_id      = aws_subnet.cluster_subnet.id
	route_table_id = aws_route_table.cluster_route_table.id
}

resource "aws_route_table_association" "backup_subnet_route_table_association" {
	subnet_id      = aws_subnet.backup_subnet.id
	route_table_id = aws_route_table.cluster_route_table.id
}

resource "aws_security_group" "lb_security_group" {
  name                   = "load-balancer-security-group"
  vpc_id                 = aws_vpc.cluster_vpc.id
  revoke_rules_on_delete = "true"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "master_security_group" {
  name                   = "master-security-group"
  vpc_id                 = aws_vpc.cluster_vpc.id
  revoke_rules_on_delete = "true"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "core_security_group" {
  name                   = "core-security-group"
  vpc_id                 = aws_vpc.cluster_vpc.id
  revoke_rules_on_delete = "true"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lb_to_master" {
  type                     = "ingress"
  from_port                = 8890
  to_port                  = 8890
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_security_group.id
  security_group_id        = aws_security_group.master_security_group.id
}

resource "aws_security_group_rule" "ssh_to_master" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.master_security_group.id
}

resource "aws_security_group_rule" "master_to_master" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.master_security_group.id
  security_group_id        = aws_security_group.master_security_group.id
}

resource "aws_security_group_rule" "core_to_core" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.core_security_group.id
  security_group_id        = aws_security_group.core_security_group.id
}

resource "aws_security_group_rule" "ssh_to_core" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.core_security_group.id
}

resource "aws_security_group_rule" "master_to_core" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.master_security_group.id
  security_group_id        = aws_security_group.core_security_group.id
}

resource "aws_security_group_rule" "core_to_master" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.core_security_group.id
  security_group_id        = aws_security_group.master_security_group.id
}