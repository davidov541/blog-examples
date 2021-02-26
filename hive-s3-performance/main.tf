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

module "load-balancer" {
	source = "./load-balancer"

	load_balancer_security_group = module.networking.load_balancer_security_group
	cluster_subnet_id = module.networking.cluster_subnet_id
	backup_subnet_id = module.networking.backup_subnet_id
	cluster_vpc_id = module.networking.cluster_vpc_id
	emr_master_id = module.emr.emr_master_id
}