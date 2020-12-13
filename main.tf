provider "aws" {
	region = "eu-central-1"
}

resource "aws_key_pair" "ssh_key" {
	key_name   = "ssh_key"
	public_key = file("key.pub")
}

resource "aws_instance" "bastion" {
	ami = "ami-08a9668cc42e6dfe7"
	instance_type = "t2.micro"
	security_groups = [ aws_security_group.sg1.id ]
	subnet_id = aws_subnet.bastion_subnet.id
	associate_public_ip_address = true
	key_name = "ssh_key"
	tags = {
		Name = "Bastion"
	}
}

resource "aws_instance" "internal" {
	ami = "ami-08a9668cc42e6dfe7"
	instance_type = "t2.micro"
	security_groups = [ aws_security_group.sg2.id ]
	subnet_id = aws_subnet.internal_subnet.id
	key_name = "ssh_key"

	tags = {
		Name = "Internal"
	}
}

resource "aws_security_group" "sg1" {
	vpc_id = aws_vpc.vpc1.id

	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["86.57.255.0/24", "188.163.115.173/32", aws_vpc.vpc1.cidr_block,
		aws_vpc.vpc2.cidr_block]
		
	}

	ingress {
		from_port = 8
		to_port = 0
		protocol = "icmp"
		cidr_blocks = ["86.57.255.0/24", "188.163.115.173/32", aws_vpc.vpc1.cidr_block,
		aws_vpc.vpc2.cidr_block]
		
	}

	tags = {
		Name = "SG1"
	}
}

resource "aws_security_group" "sg2" {
	vpc_id = aws_vpc.vpc2.id
	
	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = [aws_vpc.vpc1.cidr_block, aws_vpc.vpc2.cidr_block]
	}

	ingress {
		from_port = 8
		to_port = 0
		protocol = "icmp"
		cidr_blocks = [aws_vpc.vpc1.cidr_block, aws_vpc.vpc2.cidr_block]
	}

	tags = {
		Name = "SG2"
	}
}
