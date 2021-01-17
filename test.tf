# Author: Abdul-Hameed Ahmed
# DESCRIPTION:
# The purpose of this file is to create a cloud infrastructure provisioning the following resources: 
# VPC, Internet Gateway, Route Table, Subnet, Security Group, Network interface, Elastic IP address, 
# EC2 Instance (Amazon Linux 2). This file creates a custom VPC, and links and Internet Gateway as well as
# the necessary networking components. Afterwards we create an EIP address and place it on the network interface
# on our EC2 instance. The security groups will configure ports 22, 80, 443 to allow the web server to allow incoming 
# traffic to be open for all routes and we upload a user data script for installing and setting up the HTTPD web server. 
# END OF DESCRIPTION



# Adding AWS default profile to Terraform file. 
provider "aws" {
    profile = "default"
    region = "us-east-1"
}

# 1. Create custom Virtual Private Cloud (VPC)
resource "aws_vpc" "DevVPC" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "Development"
    }
}

# 2. Create Internet Gateway (IGW)
# This will ensure our resources that we create will have access to the internet 
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.DevVPC.id
}

# 3. Create a custom route table (RT)
resource "aws_route_table" "dev-route-table" {
    vpc_id = aws_vpc.DevVPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id      = aws_internet_gateway.gw.id 
    }

    tags = {
        Name = "Dev"
    }
}

# 4. Create a Subnet
resource "aws_subnet" "subnet-1" {
    vpc_id              = aws_vpc.DevVPC.id 
    cidr_block          = "10.0.1.0/24"
    availability_zone   = "us-east-1a"

    tags = {
        Name = "dev-subnet"
    }
}

# 5. Associate subnet with route table 
resource "aws_route_table_association" "a" {
    subnet_id               = aws_subnet.subnet-1.id 
    route_table_id      = aws_route_table.dev-route-table.id 
}

# 6. Create security group to allow port 22, 80, 443
resource "aws_security_group" "Allow-Traffic" {
    name            = "Allow-WebTraffic" 
    description     = "Allow Web Inbound Traffic"
    vpc_id          = aws_vpc.DevVPC.id

    ingress {
        description = "HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_web_traffic"
    }
}

# 7. Create a network interface with an ip address from the subnet 
# From the subnet pool created from Step 4. "10.0.1.0/24"
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.Allow-Traffic.id]
}

# 8. Assign an Elastic IP to the network interface created from Step 7
resource "aws_eip" "one" {
  vpc                           = true
  network_interface             = aws_network_interface.web-server-nic.id
  associate_with_private_ip     = "10.0.1.50"
  depends_on                    = [aws_internet_gateway.gw]
}

# 9. Create an EC2 instance based off the Amazon Linux 2 image 
# Assign user data to install and launch the HTTPD web server.
resource "aws_instance" "My-WebServer" {
    ami                 = "ami-0be2609ba883822ec"
    instance_type       = "t2.micro"
    availability_zone   = "us-east-1a"
    key_name            = "myEC2"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
    }

    user_data = <<EOF
              #!/bin/bash
              # get admin privileges
              sudo su
              # install httpd web server on Amazon Linux 2 
              yum update -y
              yum install -y httpd.x86_64
              systemctl start httpd.service
              systemctl enable httpd.service
              echo "Hello World! This is: $(hostname -f)" > /var/www/html/index.html
    EOF

    tags = {
        Name = "AL2-TestServer"
    }

}
