output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main_app_vpc.id
}

output "public_subnet_names" {
  value = aws_subnet.main_app_public_subnet[*].tags["Name"]
}
output "private_app_subnet_names" {
  value = aws_subnet.main_app_private_subnet_app[*].tags["Name"]
}

output "private_data_subnet_names" {
  value = aws_subnet.main_app_private_subnet_data[*].tags["Name"]
}

output "load_balancer_dns" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main_app_alb.dns_name

}

output "EFS_FS_ID" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.main_app_efs.id

}

output "RDS_ENDPOINT" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.db_instance.endpoint

}

output "rds_domain" {
  description = "The domain of the RDS instance"
  value       = aws_db_instance.db_instance.address

}


