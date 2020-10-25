provider "aws" {
  profile = var.profile
  region  = var.region_primary
  alias   = "region_primary"
}

provider "aws" {
  profile = var.profile
  region  = var.region_secondary
  alias   = "region_secondary"
}