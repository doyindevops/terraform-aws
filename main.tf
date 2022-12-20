provider "aws" {
    region = "eu-west-2"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}


resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"

    }
}

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}
resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []  

    }
    
    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true 
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "ec2_public_ip" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

resource "aws_key_pair" "ssh-key" {
    key_name = "terraform-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDUDMgT13Kb3srBoviG+aSiwWgfkPgppfOHKqgALSWIwrWUSA/hukKmegQbEoj5Gsg+YlHkeiRhQNcVT5ZVAWqoQ74QzB1fXkUBroDhGs/xZI54VGlgi41myNy3LtFcNmtRRGD2fCtA1aZl4dX6cwyXtfntccdNSAY8UZihcf4Qoxo9kr0ElyZ0Kmrct5ZnqXb81rpRKTInqQruHYmSGfvaQp230EYJ5JEShmF6fzg2SgnRss+QOfKRIKM046bNAX10IQdtBUxE5agBLp8F/Cg+FsEuk13dk9a9Tdip6Fm5VCpn3NUWci2RqmITWWYUioKcroInQHc2M1lm0ukgsnO7g7CKE6fE6hFbkFsbEiOWulli/loTO8cv4KaUufTUf4UZTSlUW4fGkfNd0x1oKgC8XHkgbL31CViHy8kezykY8+8ILsZLZSOy9wfjH/jwmbiUoh+3XZRreJHmLf9U5xeFkiUgwkDKstua7AS9CaERIEmFC1d14aohLzrG9GZPyKM= adedoyin@DESKTOP-CLMTQJC"
}
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = "terraform-key-pair"

    user_data = file("entry-script.sh")

    tags = {
        Name = "${var.env_prefix}-server"
    }
}




