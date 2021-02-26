resource "aws_s3_bucket" "data-bucket" {
	bucket = "hive-s3-performance-data-bucket"
	acl    = "public-read-write"

	server_side_encryption_configuration {
		rule {
			apply_server_side_encryption_by_default {
				sse_algorithm = "AES256"
			}
		}
	}

	tags = {
		Name        = "Hive-S3 Performance Test Cluster Data Bucket"
	}
}