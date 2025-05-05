# Configuración de red
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "Public subnet CIDR us-east-1a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "Public subnet CIDR us-east-1b"
  type        = string
  default     = "10.0.2.0/24"
}

#Database variables
variable "private_subnet_1_cidr" {
    description = "Private subnet CIDR us-east-1a (RDS)"
    type = string
    default = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
    description = "Private subnet CIDR us-east-1b (RDS)"
    type = string
    default = "10.0.4.0/24"
}

variable "db_instance_class" {
    description = "Instance type for database"
    type = string
    default = "db.t3.micro"
}

variable "db_name" {
    description = "Database name"
    type = string
    default = "ecommerce"
}

variable "db_username" {
    description = "Database user"
    type = string
    default = "dbadmin"
}

variable "db_password" {
    description = "Database password"
    type = string
    sensitive = true
}

#EC2 variables
variable "instance_type" {
    description = "EC2 instance type"
    type = string
    default = "t2.micro"
}

variable "key_name" {
    description = "SSH key pair name"
    type = string
    default = "vockey"
}  

#Region and AZ variables
variable "region" {
    description = "AWS region"
    type = string
    default = "us-east-1"
}

variable "az_a" {
    description = "Availability zone A"
    type = string
    default = "us-east-1a"
}

variable "az_b" {
    description = "Availability zone b"
    type = string
    default = "us-east-1b"
}

#App repository variable
variable "app_repo" {
    description = "Application repository URL"
    type = string
    default = "https://github.com/mauricioamendola/simple-ecomme.git"
}

