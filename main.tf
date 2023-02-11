terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "ayse-project208-todo-app" #you need to create your s3 bucket with the same name as here before you run this terraform file!
    key = "backend/tf-backend-jenkins.tfstate"
    region = "us-west-2"
    
  }
}

provider "aws" {
  region = "us-west-2"
}

variable "tags" {
  default = ["postgresql", "nodejs", "react"]
}


variable "user" {
  default = "ayse"
  
}
# Attach ec2 role
resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
# Attach instance profile
resource "aws_iam_instance_profile" "jenkins-project-profile" {
 name = "jenkins-project-profile"
 role = aws_iam_role.ec2_role.name 

}
resource "aws_instance" "managed_nodes" {
  ami = "ami-0ceecbb0f30a902a6"
  count = 3
  instance_type = "t2.micro"
  key_name = "C27"  # you need to put your pemkey in here
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.jenkins-project-profile.name
  tags = {
    Name = "ansible_${element(var.tags, count.index )}"
    stack = "ansible_project"
    environment = "development_1"
  }
}

resource "aws_security_group" "tf-sec-gr" {
  name = "project208-sec-gr"
  tags = {
    Name = "project208-sec-gr"
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    protocol    = "tcp"
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "react_ip" {
  value = "http://${aws_instance.managed_nodes[2].public_ip}:3000"
}

output "node_public_ip" {
  value = aws_instance.managed_nodes[1].public_ip

}

output "postgre_private_ip" {
  value = aws_instance.managed_nodes[0].private_ip

}
