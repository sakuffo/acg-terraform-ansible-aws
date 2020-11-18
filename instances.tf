#Get Linux AMI ID using SSM parameter endpoint in primary
data "aws_ssm_parameter" "linuxAMI_primary" {
  provider = aws.region-primary
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Get Linux AMI ID using SSM parameter endpoint in secondary
data "aws_ssm_parameter" "linuxAMI_secondary" {
  provider = aws.region-secondary
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Create key-pair for logging into EC2 in primary
resource "aws_key_pair" "primary_key" {
  provider   = aws.region-primary
  key_name   = "jenkins"
  public_key = file("~/.ssh/jenkins.pub")
}

#Create key-pair for logging into EC2 in secondary
resource "aws_key_pair" "secondary_key" {
  provider   = aws.region-secondary
  key_name   = "jenkins"
  public_key = file("~/.ssh/jenkins.pub")
}

#Create and bootstraap EC2 in primary
resource "aws_instance" "jenkins-primary" {
  provider                    = aws.region-primary
  ami                         = data.aws_ssm_parameter.linuxAMI_primary.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.primary_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_primary.id]
  subnet_id                   = aws_subnet.primary_subnet_1.id
  tags = {
    Name = "jenkins_primary_tf"
  }
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --region ${var.region-primary} --instance-ids ${self.id}\nansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/install_primary.yaml"
  }
  depends_on = [aws_main_route_table_association.set-primary-default-rt-assoc]
}


#Create and bootstraap EC2 in secondary
resource "aws_instance" "jenkins-secondary" {
  provider                    = aws.region-secondary
  count                       = var.secondary-count
  ami                         = data.aws_ssm_parameter.linuxAMI_secondary.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.secondary_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_secondary.id]
  subnet_id                   = aws_subnet.secondary_subnet_1.id
  depends_on                  = [aws_main_route_table_association.set-secondary-default-rt-assoc, aws_instance.jenkins-primary, ]
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "java -jar /home/ec2-user/jenkins-cli.jar -auth @/home/ec2-user/jenkins_auth -s http://${self.tags.Primary_Private_IP}:8080 delete-node ${self.private_ip}"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/jenkins")
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --region ${var.region-secondary} --instance-ids ${self.id}\nansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} primary_ip=${self.tags.Primary_Private_IP}' ansible_templates/install_secondary.yaml"
  }
  tags = {
    Name = join("_", ["jenkins-secondary_tf", count.index + 1])
    Primary_Private_IP = aws_instance.jenkins-primary.private_ip
  }
}
