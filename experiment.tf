# Adding AWS default profile to Terraform file. 
provider "aws" {
    profile = "default"
    region = "us-east-1"
}

# Adding default VPC info to Terraform file. 
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# Create an EC2 instance based off the Amazon Linux 2 image 
# Assign user data to install and launch the HTTPD web server.
resource "aws_instance" "My-WebServer" {
    ami                 = "ami-0be2609ba883822ec"
    instance_type       = "t2.micro"

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
        Name = "AL2-Server"
    }

}

# Create a security group called "Allow-Traffic" that have the following ports open:
# Ports 22, 80, 443 to access server.
resource "aws_security_group" "Allow-Traffic" {
    name            = "Allow-WebTraffic" 
    description     = "Allow Web Inbound Traffic"
    vpc_id          = aws_default_vpc.default.id

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

# Create a Network-interface attachement and assign the security group created to the EC2 instance.
resource "aws_network_interface_sg_attachment" "sg_attachment" {
    security_group_id       = aws_security_group.Allow-Traffic.id 
    network_interface_id    = aws_instance.My-WebServer.primary_network_interface_id 
}