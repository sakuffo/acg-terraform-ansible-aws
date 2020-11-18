terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "sakuffo"

    workspaces {
      name = "acg-terraform-ansible-aws"
    }
  }
}
