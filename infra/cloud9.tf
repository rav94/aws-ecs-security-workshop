# resource "aws_cloud9_environment_ec2" "cloud9-instance" {
#   instance_type = "t2.small"
#   name          = "${var.env}"
#   owner_arn     = "arn:aws:iam::${var.aws-account-id}:root"
#   connection_type = "CONNECT_SSM"
#   subnet_id = "${module.vpc.private_subnets[0]}"
  
#   tags = {
#       Terraform	= true
#   }
# }