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