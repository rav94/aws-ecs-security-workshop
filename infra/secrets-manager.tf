resource "aws_secretsmanager_secret" "dynamodb-table-name" {
  name                    = "DynamoDB-Table-Name"
  value                   = "UsersTable-${var.env}"
  recovery_window_in_days = "0"
}