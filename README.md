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

# The --auto-approve function simply bypasses the required approval and simply executes the command before the switch
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
