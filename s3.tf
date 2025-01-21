resource "aws_s3_bucket" "codepipeline_s3_bucket" {
  bucket = "codepipeline-jnc-bucket"

  force_destroy = true
}