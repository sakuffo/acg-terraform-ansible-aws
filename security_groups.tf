#Create SG for LB, only TCP/80,TCP/443 and outbound access
resource "aws_security_group" "lb_sg" {
  provider    = aws.region_primary
  name        = "lb-sg"
  description = "Allow 443 and traffic to Jenkins SG"
  vpc_id      = aws_vpc.vpc_primary.id
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere for redirection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create SG for allowing TCP/8080 from * and TCP/22 from your IP in primary vpc
resource "aws_security_group" "jenkins_sg_primary" {
  provider    = aws.region_primary
  name        = "jenkins-sg-primary"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_primary.id
  ingress {
    description = "Allow 22 from our public IP(s)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description     = "Allow anyone on port 8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    description = "allow traffic from secondary"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.10.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create SG for allowing TCP/22 from your IP in secondary vpc
resource "aws_security_group" "jenkins_sg_secondary" {
  provider    = aws.region_secondary
  name        = "jenkins-sg-secondary"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_secondary.id
  ingress {
    description = "Allow 22 from our public ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from primary"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.10.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}