terraform {
	required_providers {
		aws = {
			version = "~> 3.27"
		}
	}
}

provider "aws" {
	profile = "default"
	region  = "us-east-2"
}

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

data "aws_iam_policy_document" "emr_assume_role" {
	statement {
		effect = "Allow"

		principals {
			type        = "Service"
			identifiers = ["elasticmapreduce.amazonaws.com"]
		}

		actions = ["sts:AssumeRole"]
	}
}

resource "aws_iam_role" "emr_service_role" {
	name               = "emrServiceRole"
	assume_role_policy = data.aws_iam_policy_document.emr_assume_role.json
}

resource "aws_iam_role_policy_attachment" "emr_service_role" {
	role       = aws_iam_role.emr_service_role.name
	policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

data "aws_iam_policy_document" "ec2_assume_role" {
	statement {
	effect = "Allow"
	principals {
		type        = "Service"
		identifiers = ["ec2.amazonaws.com"]
	}
	actions = ["sts:AssumeRole"]
	}
}

resource "aws_iam_role" "emr_ec2_instance_profile" {
	name               = "PerformanceTestJobFlowInstanceProfile"
	assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "emr_ec2_instance_profile" {
	role       = aws_iam_role.emr_ec2_instance_profile.name
	policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "cluster_profile" {
	name = "cluster_profile"
	role = aws_iam_role.emr_ec2_instance_profile.name
}

resource "aws_emr_cluster" "cluster" {
	name          = "hive-s3-performance-test"
	release_label = "emr-5.28.0"
	applications  = ["Spark", "Hive", "Hadoop", "Zeppelin"]

	termination_protection            = false
	keep_job_flow_alive_when_no_steps = true

	ec2_attributes {
		subnet_id                         = aws_subnet.cluster_subnet.id
		emr_managed_master_security_group = aws_security_group.master_security_group.id
		emr_managed_slave_security_group  = aws_security_group.core_security_group.id
		instance_profile                  = aws_iam_instance_profile.cluster_profile.arn
		key_name                          = var.ssh_key_name
	}

	master_instance_group {
		instance_type = "m4.large"
	}

	core_instance_group {
		instance_type  = "c4.large"
		instance_count = 1

		ebs_config {
			size                 = "40"
			type                 = "gp2"
			volumes_per_instance = 1
		}
	}

	ebs_root_volume_size = 100

	service_role = aws_iam_role.emr_service_role.arn

	configurations_json = <<EOF
[
	{
		"Classification": "hadoop-env",
		"Configurations": [
		{
			"Classification": "export",
			"Properties": {
			"JAVA_HOME": "/usr/lib/jvm/java-1.8.0"
			}
		}
		],
		"Properties": {}
	},
	{
		"Classification": "spark-env",
		"Configurations": [
		{
			"Classification": "export",
			"Properties": {
			"JAVA_HOME": "/usr/lib/jvm/java-1.8.0"
			}
		}
		],
		"Properties": {}
	}
]
EOF
}

data "aws_instance" "master" {
  filter {
    name   = "dns-name"
    values = [aws_emr_cluster.cluster.master_public_dns]
  }
}

resource "aws_lb" "master_lb" {
  name               = "cluster-load-balancer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = [aws_subnet.cluster_subnet.id, aws_subnet.backup_subnet.id]
}

resource "aws_lb_target_group" "zeppelin" {
  name     = "cluster-zeppelin-target-group"
  port     = "8893"
  protocol = "HTTPS"
  vpc_id   = aws_vpc.cluster_vpc.id

  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200"

    healthy_threshold   = 2
    unhealthy_threshold = 2

    interval = 10
    timeout  = 2
  }
}

resource "aws_lb_target_group_attachment" "zeppelin" {
  target_group_arn = aws_lb_target_group.zeppelin.arn
  target_id        = data.aws_instance.master.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "ssl" {
  load_balancer_arn = aws_lb.master_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.zeppelin.arn
    type             = "forward"
  }
}