resource "aws_lb" "application_lb" {
  provider           = aws.region_primary
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.primary_subnet_1.id, aws_subnet.primary_subnet_2.id]
  tags = {
    Name = "Jenkins-LB"
  }
}

resource "aws_lb_target_group" "app_lb_tg" {
  provider = aws.region_primary
  name     = "app-lb-tg"
  port     = var.webserver_port
  vpc_id   = aws_vpc.vpc_primary.id
  protocol = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = var.webserver_port
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "jenkins-target-group"
  }
}

resource "aws_lb_listener" "jenkins_listener_http" {
  provider          = aws.region_primary
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_tg.id
  }
}

resource "aws_lb_target_group_attachment" "jenkins_primary_attach" {
  provider         = aws.region_primary
  target_group_arn = aws_lb_target_group.app_lb_tg.arn
  target_id        = aws_instance.jenkins_primary.id
  port             = var.webserver_port
}