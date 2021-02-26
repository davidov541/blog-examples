module "networking" {
	source = "./networking"
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
		subnet_id                         = module.networking.cluster_subnet_id
		emr_managed_master_security_group = module.networking.master_security_group
		emr_managed_slave_security_group  = module.networking.core_security_group
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
  security_groups    = [module.networking.load_balancer_security_group]
  subnets            = [module.networking.cluster_subnet_id, module.networking.backup_subnet_id]
}

resource "aws_lb_target_group" "zeppelin" {
  name     = "cluster-zeppelin-target-group"
  port     = "8893"
  protocol = "HTTPS"
  vpc_id   = module.networking.cluster_vpc_id

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