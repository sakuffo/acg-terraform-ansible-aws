variable "profile" {
  type    = string
  default = "default"
}

variable "region-primary" {
  type    = string
  default = "us-east-1"
}

variable "region-secondary" {
  type    = string
  default = "us-west-2"
}

variable "external-ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "secondary-count" {
  type        = string
  description = "How many nodes?"
  default     = 2
}

variable "instance-type" {
  type        = string
  description = "the instance type of the nodes"
  default     = "t3.micro"
}

variable "webserver-port" {
  type    = number
  default = 8080
}

variable "dns-name" {
  type        = string
  # default     = "cmcloudlab542.info."
  description = "Please enter your DNS record ending with the '.'"
}
