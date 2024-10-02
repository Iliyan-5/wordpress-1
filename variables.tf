variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "admin123"
}

variable "db_instance_class" {
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  default = 20
}
variable "max_allocated_storage" {
  default = 30
}

variable "db_name" {
  default = "kbc_wordpress"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami_id" {
  default = "ami-0ebfd941bbafe70c6"
}

variable "wp_title" {
  default = "KBC WordPress"
}

variable "wp_admin_user" {
  default = "admin"
}

variable "wp_admin_password" {
  default = "password"
}

variable "wp_admin_email" {
  default = "iminchev24@gmail.com"
}