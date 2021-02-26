variable "cluster_profile_arn" {
    type = string
}

variable "emr_service_arn" {
    type = string
}

variable "core_security_group" {
    type = string
}

variable "master_security_group" {
    type = string
}

variable "cluster_subnet_id" {
    type = string
}

variable "ssh_key_name" {
    description = "Name of the SSH key to use to access the cluster."
    type = string
}