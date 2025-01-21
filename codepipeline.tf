resource "aws_codepipeline" "codepipeline" {
  name = "jnc-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    location = aws_s3_bucket.codepipeline_s3_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      run_order        = 1

      configuration = {
        ConnectionArn   = aws_codestarconnections_connection.wlstmd.arn
        FullRepositoryId = "wlstmd/jnc-commit"
        BranchName      = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]
      version = 1
      run_order = 2

      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name = "Deploy"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      input_artifacts = ["build_output"]
      version = 1
      run_order = 3

      configuration = {
        ApplicationName = aws_codedeploy_app.codedeploy.name
        DeploymentGroupName = aws_codedeploy_deployment_group.codedeploy_group.deployment_group_name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "wlstmd" {
  name          = "wlstmd"
  provider_type = "GitHub"
}