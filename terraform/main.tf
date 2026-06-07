data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "ec2-lb-lab-web-sg"
  description = "Allow HTTP and SSH access for EC2 load balancer lab"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP from internet for initial test"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Replace this with your own public IP if you want SSH.
  # Example: ["203.0.113.10/32"]
  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["130.195.223.27/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "ec2-lb-lab-web-sg"
    Project = "EC2-Behind-a-Load-Balancer"
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx
              echo "EC2 instance running behind future load balancer" > /usr/share/nginx/html/index.html
              echo "OK" > /usr/share/nginx/html/health
              EOF

  tags = {
    Name    = "ec2-lb-lab-web"
    Project = "EC2-Behind-a-Load-Balancer"
  }
}