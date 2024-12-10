provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MySQL-VPC"
  }
}

# Create a Subnet
resource "aws_subnet" "main" {
  vpc_id                 = aws_vpc.main.id
  cidr_block             = "10.0.1.0/24"
  availability_zone      = "us-east-1a"  # Change as needed
  map_public_ip_on_launch = true  # Enable public IP assignment
  tags = {
    Name = "MySQL-Subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MySQL-IGW"
  }
}

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MySQL-RouteTable"
  }
}

# Create Route for the internet gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate the Route Table with the subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Create Security Group for EC2
resource "aws_security_group" "mysql_ec2_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "mysql_ec2_sg"
  description = "Security group for MySQL EC2 instance"
  
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open MySQL port to the world (change this to restrict access)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open SSH port to the world (be cautious about this)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySQL-EC2-SG"
  }
}

# Reference the existing SSH Key Pair (ensure it's available in your AWS account)
data "aws_key_pair" "mysql_key" {
  key_name = "jenkins"  # Replace with your actual key name in AWS
}

# Create EC2 Instance
resource "aws_instance" "mysql_instance" {
  ami                    = "ami-005fc0f236362e99f"  # Example AMI, update with the latest Ubuntu AMI ID
  instance_type           = "t2.micro"
  subnet_id               = aws_subnet.main.id
  vpc_security_group_ids  = [aws_security_group.mysql_ec2_sg.id]  # Reference security group by ID
  key_name                = data.aws_key_pair.mysql_key.key_name

  tags = {
    Name = "MySQL-EC2"
  }

  # Upload and execute the Ansible playbook after instance is created
  provisioner "remote-exec" {
    inline = [
      "echo 'Installing Ansible...'",
      "sudo apt-get update",
      "sudo apt-get install -y ansible",
      "echo 'Running Ansible Playbook...'",
      "ansible-playbook /home/ubuntu/setup.yml"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)  # Use variable for private key path
      host        = self.public_ip
    }
  }

  # Upload the Ansible playbook to the instance
  provisioner "file" {
    source      = "setup.yml"  # Path to your local Ansible playbook
    destination = "/home/ubuntu/setup.yml"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)  # Use variable for private key path
      host        = self.public_ip
    }
  }
}

# Output the Public IP of EC2
output "mysql_instance_public_ip" {
  value = aws_instance.mysql_instance.public_ip
}
