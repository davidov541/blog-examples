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