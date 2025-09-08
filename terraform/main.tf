provider "aws" {
    region = "ap-south-1"
}

#creation of vpc
resource "aws_vpc" "devops_vpc" {
    cidr_block = ""
    tags = {
        Name = "DevOps-vpc"
    }
}

#creation of subnet
resource "aws_subnet" "devops_subnet" {
    vpc_id = aws_vpc.devops_vpc.id
    cidr_block = ""
    map_public_ip_on_launch = true
    availability_zone       = "ap-south-1a"
}

#internet gateway
resource "aws_internet_gateway" "gw"{
    vpc_id = aws_vpc.devops_vpc.id
}

#Route table
resource "aws_route_table" "rt"{
    vpc_id = aws_vpc.devops_vpc.id

    route {
        cidr_block = ""
        gateway_id = aws_internet_gateway.gw.id
    }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.devops_subnet.id
  route_table_id = aws_route_table.rt.id
}

# security group
resource "aws_security_group" "devops_sg" {
    vpc_id = aws_vpc.devops_vpc.id

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# EC2 instance (2)
resource "aws_instance" "devops_servers" {
    count         = 2
    ami           = "ami-0e306788ff2473ccb" # Ubuntu 22.04 LTS
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.devops_subnet.id
    vpc_security_group_ids = [aws_security_group.devops_sg.id]
    key_name      = "Monkey" # Replace with your AWS key pair

    tags = {
        Name = ""
    }
}

# Load Balancer
resource "aws_lb" "devops_alb" {
  name               = "devops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.devops_sg.id]
  subnets            = [aws_subnet.devops_subnet.id]
}

resource "aws_lb_target_group" "devops_tg" {
  name     = "devops-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.devops_vpc.id
}

resource "aws_lb_target_group_attachment" "devops_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.devops_tg.arn
  target_id        = aws_instance.devops_servers[count.index].id
  port             = 80
}

resource "aws_lb_listener" "devops_listener" {
  load_balancer_arn = aws_lb.devops_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devops_tg.arn
  }
}
