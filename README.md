# Simple document on provisioning resources using Terraform on Amazon Web Services (AWS)
Note: You will need to already have Terraform install on your local machine primary to using these files. 
Also you will need to already have your access keys configure on your local host. 

```tf
# This command is used for initialize the directory containing your terraform file
terraform init

# This command does a dry-run execution of what you intend on provisioning using Terraform
terraform plan

# This command executes your terraform file and will require you to approve the execution using "yes"
terrafom apply

# This command will destroy all of the resources provision in the current terraform file.
terraform destroy

# The --auto-approve function simply bypasses the required approval and simply executes the command.
terraform apply --auto-approve
terraform destroy --auto-approve
```

## Creating an EC2 instance using Terraform  
The following snippet will provision an Amazon Linux 2 instance and pull the user data script that will install Httpd server. 
```tf
# Adding AWS default profile to Terraform file. 
provider "aws" {
    profile = "default"
    region = "us-east-1"
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
```

## Adding a custom security group to your Httpd web server (Amazon Linux 2)
The following snippet will create a security group that will configure ports the following ports: 22, 80, 443

```tf
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
```

