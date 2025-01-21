resource "aws_codebuild_project" "codebuild" {
  name = "jnc-build"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "LOCAL"
    modes = [
      "LOCAL_DOCKER_LAYER_CACHE"
    ]
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/jnc-build"
      stream_name = "build_log"
    }
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    type = "LINUX_CONTAINER"
    image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    privileged_mode = true

    environment_variable {
      name  = "AWS_REGION"
      value = "ap-northeast-2"
    }

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = "gateway"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "362708816803"
    }
  }
}