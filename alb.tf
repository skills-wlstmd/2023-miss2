resource "aws_lb" "gateway_alb" {
  name = "gateway-alb"
  internal = true
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb_sg.id
  ]
  subnets = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]
}

resource "aws_lb_target_group" "gateway_alb_tg" {
  name = "gateway-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/health"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "gateway_alb_listener" {
  load_balancer_arn = aws_lb.gateway_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.gateway_alb_tg.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_target_group_attachment" "gateway_alb_tg_attachment" {
  count            = length(aws_instance.gateway_app)
  target_group_arn = aws_lb_target_group.gateway_alb_tg.arn
  target_id        = aws_instance.gateway_app[count.index].id
  port             = 8080
}