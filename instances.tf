#Get Linux AMI ID using SSM parameter endpoint in primary
data "aws_ssm_parameter" "linuxAMI_primary" {
  provider = aws.region_primary
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Get Linux AMI ID using SSM parameter endpoint in secondary
data "aws_ssm_parameter" "linuxAMI_secondary" {
  provider = aws.region_secondary
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Create key-pair for logging into EC2 in primary
resource "aws_key_pair" "primary_key" {
  provider   = aws.region_primary
  key_name   = "jenkins"
  public_key = file("~/.ssh/jenkins.pub")
}

#Create key-pair for logging into EC2 in secondary
resource "aws_key_pair" "secondary_key" {
  provider   = aws.region_secondary
  key_name   = "jenkins"
  public_key = file("~/.ssh/jenkins.pub")
}

#Create and bootstraap EC2 in primary
resource "aws_instance" "jenkins_primary" {
  provider                    = aws.region_primary
  ami                         = data.aws_ssm_parameter.linuxAMI_primary.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.primary_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_primary.id]
  subnet_id                   = aws_subnet.primary_subnet_1.id
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --region ${var.region_primary} --instance-ids ${self.id} --profile ${var.profile}\nansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ./ansible_templates/install_primary.yaml"
  }
  tags = {
    Name = "jenkins_primary_tf"
  }
  depends_on = [aws_main_route_table_association.set-primary-default-rt-assoc]
}


#Create and bootstraap EC2 in secondary
resource "aws_instance" "jenkins_secondary" {
  provider                    = aws.region_secondary
  count                       = var.secondary_count
  ami                         = data.aws_ssm_parameter.linuxAMI_secondary.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.secondary_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_secondary.id]
  subnet_id                   = aws_subnet.secondary_subnet_1.id

  tags = {
    Name = join("-", ["jenkins_secondary_tf", count.index + 1])
  }
  depends_on = [aws_main_route_table_association.set-secondary-default-rt-assoc, aws_instance.jenkins_primary]

  provisioner "local-exec" {
    command =  "aws ec2 wait instance-status-ok --region ${var.region_secondary} --instance-ids ${self.id} --profile ${var.profile}\nansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ./ansible_templates/install_secondary.yaml"
  }

  # user_data = <<EOF
  #             #! /bin/bash
  #             sudo yum update
  #             sudo yum install -y jq
  #             EOF

}