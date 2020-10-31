output "Jenkins-Main-Node-Public-IP" {
  value = aws_instance.jenkins_primary.public_ip
}

output "Jenkins-Secondary-Node-Public-IP" {
  value = {
    for instance in aws_instance.jenkins_secondary : instance.id => instance.public_ip
  }
}