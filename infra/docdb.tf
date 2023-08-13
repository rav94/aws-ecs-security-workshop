data "aws_secretsmanager_secret" "docdb-password-by-arn" {
  arn = aws_secretsmanager_secret.docdb-service.arn
} 

data "aws_secretsmanager_secret_version" "docdb-password-current" {
  secret_id = data.aws_secretsmanager_secret.docdb-password-by-arn.id
}

resource "aws_docdb_subnet_group" "docdb-service" {
  name       = "docdb-${var.env}"
  subnet_ids = flatten(["${module.vpc.database_subnets}"])
}

resource "aws_docdb_cluster_instance" "docdb-service" {
  count              = 3
  identifier         = "docdb-${var.env}-${count.index}"
  cluster_identifier = "${aws_docdb_cluster.docdb-service.id}"
  instance_class     = "${var.docdb-instance-class}"
}

resource "aws_docdb_cluster" "docdb-service" {
  skip_final_snapshot     = true
  db_subnet_group_name    = "${aws_docdb_subnet_group.docdb-service.name}"
  cluster_identifier      = "docdb-${var.env}"
  engine                  = "docdb"
  master_username         = "docdb_admin"
  master_password         = data.aws_secretsmanager_secret_version.docdb-password-current.secret_string
  db_cluster_parameter_group_name = "${aws_docdb_cluster_parameter_group.docdb-service.name}"
  vpc_security_group_ids = ["${aws_security_group.docdb-service.id}"]
}

resource "aws_docdb_cluster_parameter_group" "docdb-service" {
  family = "docdb5.0"
  name = "docdb-${var.env}"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}

output "docdb_reader_endpoint" {
  description = "The reader endpoint of DocumentDB"
  value       = aws_docdb_cluster.docdb-service.reader_endpoint
}

output "docdb_endpoint" {
  description = "The endpoint of DocumentDB"
  value       = aws_docdb_cluster.docdb-service.endpoint
}