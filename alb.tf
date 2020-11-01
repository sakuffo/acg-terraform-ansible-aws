resource "aws_lb" "application-lb" {
  provider           = aws.region_primary
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  tags = {
    Name = "Jenkins-LB"
  }
}

resource "aws_lb_target_group" "app_lb_tg" {
  provider = aws.region_primary
  name     = "app-lb-tg"
  port     = "instance"
  vpc_id   = aws_vpc.vpc_primary.id
  protocol = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = var.webserver-port
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "jenkins-target-group"
  }
}