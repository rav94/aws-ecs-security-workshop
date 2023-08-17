resource "aws_dynamodb_table" "users-dynamodb-table" {
  name           = "UsersTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "first_name"
  range_key      = "last_name"

  attribute {
    name = "first_name"
    type = "S"
  }

  attribute {
    name = "last_name"
    type = "S"
  }
}