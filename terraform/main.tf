data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
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
    description     = "Allow HTTP from only ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH capability.
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
  subnet_id                   = data.aws_subnets.default.ids[0]
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

resource "aws_security_group" "alb_sg" {
  name        = "ec2-lb-lab-alb-sg"
  description = "Allow HTTP access to the Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP from internet to ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic from ALB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ec2-lb-lab-alb-sg"
    Project     = "EC2-Behind-a-Load-Balancer"
    Environment = "lab"
  }
}

resource "aws_lb" "app_alb" {
  name               = "ec2-lb-lab-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = {
    Name        = "ec2-lb-lab-alb"
    Project     = "EC2-Behind-a-Load-Balancer"
    Environment = "lab"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "ec2-lb-lab-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "ec2-lb-lab-tg"
    Project     = "EC2-Behind-a-Load-Balancer"
    Environment = "lab"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

