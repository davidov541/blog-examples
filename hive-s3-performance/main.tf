module "networking" {
	source = "./networking"
}

module "iam" {
	source = "./iam"
}

module "emr" {
	source = "./emr"

	cluster_profile_arn = module.iam.cluster_profile_arn
	emr_service_arn = module.iam.emr_service_arn
	core_security_group = module.networking.core_security_group
	master_security_group = module.networking.master_security_group
	cluster_subnet_id = module.networking.cluster_subnet_id
	ssh_key_name = var.ssh_key_name
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
  target_id        = module.emr.emr_master_id

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