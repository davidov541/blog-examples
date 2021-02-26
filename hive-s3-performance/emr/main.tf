
resource "aws_emr_cluster" "cluster" {
	name          = "hive-s3-performance-test"
	release_label = "emr-5.28.0"
	applications  = ["Spark", "Hive", "Hadoop", "Zeppelin"]

	termination_protection            = false
	keep_job_flow_alive_when_no_steps = true

	ec2_attributes {
		subnet_id                         = var.cluster_subnet_id
		emr_managed_master_security_group = var.master_security_group
		emr_managed_slave_security_group  = var.core_security_group
		instance_profile                  = var.cluster_profile_arn
		key_name                          = var.ssh_key_name
	}

	master_instance_group {
		instance_type = "m4.large"
	}

	core_instance_group {
		instance_type  = "c4.large"
		instance_count = 2

		ebs_config {
			size                 = "40"
			type                 = "gp2"
			volumes_per_instance = 1
		}
	}

	ebs_root_volume_size = 100

	service_role = var.emr_service_arn

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

resource "aws_emr_instance_group" "task_nodes" {
  cluster_id     = aws_emr_cluster.cluster.id
  instance_count = 2
  instance_type  = "m5.xlarge"
  name           = "Hive-S3 Performance Test Task Nodes"
}

data "aws_instance" "master" {
  filter {
    name   = "dns-name"
    values = [aws_emr_cluster.cluster.master_public_dns]
  }
}