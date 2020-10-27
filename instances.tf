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
  public_key = file("~/.ssh/aws_rsa.pub")
}

#Create key-pair for logging into EC2 in secondary
resource "aws_key_pair" "secondary_key" {
  provider   = aws.region_secondary
  key_name   = "jenkins"
  public_key = file("~/.ssh/aws_rsa.pub")
}