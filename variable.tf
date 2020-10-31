variable "profile" {
  type    = string
  default = "default"
}

variable "region_primary" {
  type    = string
  default = "us-east-1"
}

variable "region_secondary" {
  type    = string
  default = "us-west-2"
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "secondary_count" {
  type        = string
  description = "How many nodes?"
  default     = 2
}

variable "instance_type" {
  type        = string
  description = "the instance type of the nodes"
  default     = "t3.micro"
}