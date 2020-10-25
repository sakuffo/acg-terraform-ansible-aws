## Ceate VPCs ##

#Create VPC in us-east-1
resource "aws_vpc" "vpc_primary" {
  provider             = aws.region_primary
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "primary-vpc-jenkins"
  }
}

#Create VPC in us-east-2
resource "aws_vpc" "vpc_secondary" {
  provider             = aws.region_secondary
  cidr_block           = "192.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "secondary-vpc-jenkins"
  }
}

## Ceate IGWs ##

#Create IGW in us-east-1
resource "aws_internet_gateway" "igw_primary" {
  provider = aws.region_primary
  vpc_id   = aws_vpc.vpc_primary.id
}
#Create IGW in us-west-2
resource "aws_internet_gateway" "igw_secondary" {
  provider = aws.region_secondary
  vpc_id   = aws_vpc.vpc_secondary.id
}

## Ceate subnets ##

#Get all available AZ's in VPC for primary region
data "aws_availability_zones" "azs" {
  provider = aws.region_primary
  state    = "available"
}

#Create subnet # 1 in us-east-1
resource "aws_subnet" "primary_subnet_1" {
  provider          = aws.region_primary
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_primary.id
  cidr_block        = "10.10.1.0/24"
}

#Create subnet # 2 in us-east-1
resource "aws_subnet" "primary_subnet_2" {
  provider          = aws.region_primary
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_primary.id
  cidr_block        = "10.10.2.0/24"
}
#Create subnet # 1 in us-west-1
resource "aws_subnet" "secondary_subnet_1" {
  provider = aws.region_secondary

  vpc_id     = aws_vpc.vpc_secondary.id
  cidr_block = "192.10.1.0/24"
}


## Create Peering connection request ##

#Initiate Peering connection request from us-east-1 to us-west-2

resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider    = aws.region_primary
  peer_vpc_id = aws_vpc.vpc_secondary.id
  vpc_id      = aws_vpc.vpc_primary.id
  peer_region = var.region_secondary
}

#Accept VPC peering request in us-west 2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "secondary_accept_peering" {
  provider                  = aws.region_secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept               = true
}

## Create routing tables ##

## Create Route table for Primary VPC
resource "aws_route_table" "internet_route_primary" {
  provider = aws.region_primary
  vpc_id   = aws_vpc.vpc_primary.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_primary.id
  }
  route {
    cidr_block                = "192.10.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Primary-Region-RT"
  }
}


## Overwrite default route table of Primary VPC with out route table entries
resource "aws_main_route_table_association" "set-primary-default-rt-assoc" {
  provider       = aws.region_primary
  vpc_id         = aws_vpc.vpc_primary.id
  route_table_id = aws_route_table.internet_route_primary.id
}

## Create Route table for Secondary VPC
resource "aws_route_table" "internet_route_secondary" {
  provider = aws.region_secondary
  vpc_id   = aws_vpc.vpc_secondary.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_secondary.id
  }
  route {
    cidr_block                = "10.10.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Secondary-Region-RT"
  }
}

## Overwrite default route table of Secondary VPC with out route table entries
resource "aws_main_route_table_association" "set-secondary-default-rt-assoc" {
  provider       = aws.region_secondary
  vpc_id         = aws_vpc.vpc_secondary.id
  route_table_id = aws_route_table.internet_route_secondary.id
}