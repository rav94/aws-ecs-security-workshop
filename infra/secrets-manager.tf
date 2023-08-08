resource "aws_secretsmanager_secret" "docdb-service" {
  name = "DocumentDBMasterPassword"
  recovery_window_in_days = "0"
}