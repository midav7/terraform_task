resource "aws_vpc" "vpc1" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" # gives us an internal domain name
    enable_dns_hostnames = "true" # gives us an internal host name
    tags = {
        Name = "VPC1"
    }
}

resource "aws_vpc" "vpc2" {
    cidr_block = "10.1.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true"
    tags = {
        Name = "VPC2"
    }
}

resource "aws_subnet" "bastion_subnet" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = "true" # it makes this a public subnet
    availability_zone = "eu-central-1a"
    tags = {
        Name = "vpc1-bastion-subnet"
    }
}

resource "aws_subnet" "internal_subnet" {
    vpc_id = aws_vpc.vpc2.id
    cidr_block = "10.1.0.0/24"
    availability_zone = "eu-central-1b"
    tags = {
        Name = "vpc2-internal-subnet"
    }
}

resource "aws_internet_gateway" "bastion_igw" {
    vpc_id = aws_vpc.vpc1.id
    tags = {
        Name = "bastion-igw"
    }
}

resource "aws_route" "bastion_internet_access" {
    route_table_id = aws_vpc.vpc1.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bastion_igw.id
}

resource "aws_eip" "nat_gw_eip" {
    vpc = true
}

resource "aws_nat_gateway" "bastion_ngw" {
    allocation_id = aws_eip.nat_gw_eip.id
    subnet_id = aws_subnet.bastion_subnet.id
    depends_on = [aws_internet_gateway.bastion_igw]
    tags = {
        Name = "Bastion NAT"
    }
}

data "aws_caller_identity" "current" {} # required for VPC peering

# VPC peering connection.
# Establishes a relationship resource between the VPC1 and VPC2.
resource "aws_vpc_peering_connection" "bastion_to_internal" {
    peer_owner_id = data.aws_caller_identity.current.account_id
    peer_vpc_id   = aws_vpc.vpc2.id
    vpc_id        = aws_vpc.vpc1.id
    auto_accept   = true
    tags = {
        Name = "Bastion to Internal"
    }
}

resource "aws_route" "bastion_to_internal" {
    route_table_id            = aws_vpc.vpc1.main_route_table_id
    destination_cidr_block    = aws_vpc.vpc2.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_internal.id
}

resource "aws_route" "internal_to_bastion" {
    route_table_id            = aws_vpc.vpc2.main_route_table_id
    destination_cidr_block    = aws_vpc.vpc1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_internal.id
}
