terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or the latest version you want to use
    }
  }
}

provider "aws" {
  region  = "us-east-1" # Or your preferred AWS region
  profile = "challenge"
  # You will configure credentials later
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Change as needed
  tags = {
    Name = "my-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# Create a Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "public_subnet_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create an EC2 Instance
resource "aws_instance" "example" {
  ami                    = "ami-04b4f1a9cf54c11d0" # Replace with your desired AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_subnet.id                # Launch in our subnet
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id] # Add security group
  key_name               = aws_key_pair.deployer.key_name

  user_data = templatefile("${path.module}/ssh_keys.tpl", {
    ansible_key = file("D:/projects/webserverAWS/ansible.pub") # Second Key
  })

  # This remote-exec provisioner connects to the Ansible Controller (LXC Container)
  # to automatically generate the dynamic inventory file for EC2 instances
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("C:\\Users\\Killua\\.ssh\\windows") # Windows SSH Key
      host        = "192.168.0.15"                           # LXC IP
    }
    inline = [
      "set -x", # This will print each command before executing it (for debugging)
      "echo '[ec2_instance]' > ~/ansible_1st_project/inventory/dynamic_inventory.yml",
      "echo '${aws_eip.eip.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ansible' >> ~/ansible_1st_project/inventory/dynamic_inventory.yml",
      "cat ~/ansible_1st_project/inventory/dynamic_inventory.yml", # This will print the inventory file content to the console
    ]
  }
  tags = {
    Name = "example-instance"
  }
}

#Create Security Group
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.example.id
  allocation_id = aws_eip.eip.id
}

output "public_ip" {
  value       = aws_eip.eip.public_ip
  description = "The public IP address of the EC2 instance"
}

resource "local_file" "inventory" {
  content  = "[webservers]\n${aws_eip.eip.public_ip}"
  filename = "${path.module}/ansible/inventory"
}

resource "aws_key_pair" "deployer" {
  key_name   = "webserverAWS"
  public_key = file("D:/projects/webserverAWS/webserverAWS.pub")
}