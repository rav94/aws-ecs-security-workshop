variable "aws-access-key" {
}

variable "aws-secret-key" {
}

variable "aws-region" {
    default = "us-east-1"
}

variable "aws-account-id" {
    default = "830791455757"
}

variable "env" {
    default = "ecs-security-workshop"
}

variable "docdb-instance-class" {
    default = "db.t3.medium"
}