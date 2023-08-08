variable "aws_access_key" {
}

variable "aws_secret_key" {
}

variable "aws_region" {
    default = "us-east-1"
}

variable "env" {
    default = "ecs-security-workshop"
}

variable "docdb_instance_class" {
    default = "db.t3.medium"
}

variable "docdb_password" {
}