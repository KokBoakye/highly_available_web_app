variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-north-1"
}

variable "availability_zones" {
  description = "A list of availability zones in the region."
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]

}

variable "cidr_block_vpc" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

}

variable "cidr_block_public_subnet" {
  description = "The CIDR block for the public subnet."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

}

variable "cidr_block_private_subnet_app" {
  description = "The CIDR block for the public subnet."
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]

}

variable "cidr_block_private_subnet_data" {
  description = "The CIDR block for the public subnet."
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]

}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "wordpress-app"

}

variable "db_name" {
  description = "The name of the database."
  type        = string
  sensitive   = true

}

variable "db_username" {
  description = "The username for the database."
  type        = string
  sensitive   = true

}

variable "db_password" {
  description = "The password for the database."
  type        = string
  sensitive   = true

}

variable "db_host" {
  description = "The host address for the database."
  type        = string
  sensitive   = true

}

variable "db_instance_class" {
  description = "The instance class for the database."
  type        = string
  default     = "db.t3.micro"

}

variable "db_engine" {
  description = "The database engine."
  type        = string
  default     = "mysql"


}

variable "db_engine_version" {
  description = "The database engine version."
  type        = string
  default     = "8.0"

}

variable "db_allocated_storage" {
  description = "The allocated storage for the database in GB."
  type        = number
  default     = 20

}

variable "instance_type" {
  description = "The instance type for the EC2 instances."
  type        = string
  default     = "t3.micro"

}

variable "key_name" {
  description = "The name of the key pair to use for EC2 instances."
  type        = string
  default     = "Mendy"

}

variable "asg_min_size" {
  description = "The minimum size of the Auto Scaling group."
  type        = number
  default     = 2

}

variable "asg_max_size" {
  description = "The maximum size of the Auto Scaling group."
  type        = number
  default     = 4

}

variable "asg_desired_capacity" {
  description = "The desired capacity of the Auto Scaling group."
  type        = number
  default     = 2

}
