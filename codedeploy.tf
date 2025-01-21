resource "aws_codedeploy_app" "codedeploy" {
  name = "jnc-gw"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "codedeploy_group" {
  app_name              = aws_codedeploy_app.codedeploy.name
  deployment_group_name = "dev-jnc-gw"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "jnc:deploy:group"
      type  = "KEY_AND_VALUE"
      value = "gateway"
    }
  }

  load_balancer_info {
    target_group_info {
      name = "gateway-tg"
    }
  }

}