provider "aws" {
  region = "us-east-1"
}

#VPC
resource "aws_vpc" "vpc_practico_3tier" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "vpc-practico-3tier"
    }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc_practico_3tier.id

    tags = {
        Name = "vpc-practico-3tier-igw"
    }
}

#Public Subnets
resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.vpc_practico_3tier.id
    cidr_block = var.public_subnet_1_cidr
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet-1"
    }
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.vpc_practico_3tier.id
    cidr_block = var.public_subnet_2_cidr
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet-2"
    }
}

#Private Subnets
resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.vpc_practico_3tier.id
    cidr_block = var.private_subnet_1_cidr
    availability_zone = var.az_a
    map_public_ip_on_launch = false

    tags = {
        Name = "private-subnet-1"
    }
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.vpc_practico_3tier.id
    cidr_block = var.private_subnet_2_cidr
    availability_zone = var.az_b
    map_public_ip_on_launch = false

    tags = {
        Name = "private-subnet-2"
    }
}


#Route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_practico_3tier.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

#Route table association
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

#Security group for web instance
resource "aws_security_group" "ssh_http_access" {
    name = "ssh-http-access"
    description = "Allow SSH and HTTP"
    vpc_id = aws_vpc.vpc_practico_3tier.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH from anywhere"
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP from anywhere"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all the egress traffic"
    }

    tags = {
      Name = "sg-ssh-http-access"
    }
}

#Security group for MySQL database
resource "aws_security_group" "mysql_access" {
    name = "mysql-access"
    description = "Allow MySQL access from web instances"
    vpc_id = aws_vpc.vpc_practico_3tier.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.ssh_http_access.id]
        description = "MySQL from web servers"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all the egress traffic"
    }

    tags = {
      Name = "sg-mysql-access"
    }
}

#Security group for ALB
resource "aws_security_group" "alb_sg" {
    name = "alb-sg"
    description = "Security group for ALB"
    vpc_id = aws_vpc.vpc_practico_3tier.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP from anywhere"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all the egress traffic"
    }

    tags = {
      Name = "sg-alb"
    }
}

#Subnet groups for RDS
resource "aws_db_subnet_group" "mysql_subnet_group" {
    name = "mysql-subnet-group"
    subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

    tags = {
      Name = "My SQL Subnet group"
    }
}

#MySQL RDS instance
resource "aws_db_instance" "mysql_db" {
    allocated_storage = 20
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = var.db_instance_class
    db_name = var.db_name
    username = var.db_username
    password = var.db_password
    parameter_group_name = "default.mysql5.7"
    db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name
    vpc_security_group_ids = [aws_security_group.mysql_access.id]
    skip_final_snapshot = true
    multi_az = false

    tags = {
      Name = "mysql-db"
    }
}

#Get the latest AMI for Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance 1
resource "aws_instance" "webapp_server01" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ssh_http_access.id]
  user_data = templatefile("${path.module}/user_data.sh", {
    db_host     = aws_db_instance.mysql_db.address
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = var.db_password
    app_repo    = var.app_repo
  })

  tags = {
    Name = "webapp-server01"
  }

  # Provisioner to run a local script
  provisioner "local-exec" {
    command = "echo The instance ${self.id} has been created with IP ${self.public_ip} > instance_info.txt"
  }

  
}

# Instance 2
resource "aws_instance" "webapp_server02" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.ssh_http_access.id]
  user_data = templatefile("${path.module}/user_data.sh", {
    db_host     = aws_db_instance.mysql_db.address
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = var.db_password
    app_repo    = var.app_repo
  })

  tags = {
    Name = "webapp-server02"
  }

  # Provisioner to run a local script
  provisioner "local-exec" {
    command = "echo The instance ${self.id} has been created with IP ${self.public_ip} >> instance_info.txt"
  }
}

#Network Load Balancer
resource "aws_lb" "webapp_nlb" {
  name               = "webapp-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "webapp-nlb"
  }
}

#Target group for NLB
resource "aws_lb_target_group" "webapp_tg_nlb" {
  name     = "webapp-tg-nlb"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc_practico_3tier.id
  
  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }
}

#Listener for NLB
resource "aws_lb_listener" "webapp_listener_nlb" {
  load_balancer_arn = aws_lb.webapp_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg_nlb.arn
  }
}

#Associate the instances to the target group
resource "aws_lb_target_group_attachment" "webapp_server01_attachment_nlb" {
  target_group_arn = aws_lb_target_group.webapp_tg_nlb.arn
  target_id        = aws_instance.webapp_server01.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webapp_server02_attachment_nlb" {
  target_group_arn = aws_lb_target_group.webapp_tg_nlb.arn
  target_id        = aws_instance.webapp_server02.id
  port             = 80
}
