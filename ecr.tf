resource "aws_ecr_repository" "ecr" {
  name = "gateway"
  force_delete = true
}