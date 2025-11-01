resource "aws_vpc" "main_app_vpc" {
  cidr_block = var.cidr_block_vpc
  tags = {
    Name = "{var.project_name}-vpc"
  }

}

#two public subnets
resource "aws_subnet" "main_app_public_subnet" {
  vpc_id            = aws_vpc.main_app_vpc.id
  cidr_block        = var.cidr_block_public_subnet[count.index]
  count             = 2
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.project_name}-public-${var.availability_zones[count.index]}"
  }
}

resource "aws_internet_gateway" "main_app_igw" {
  vpc_id = aws_vpc.main_app_vpc.id
  tags = {
    Name = "wordpress_app_igw"
  }
}

resource "aws_subnet" "main_app_private_subnet_app" {
  vpc_id            = aws_vpc.main_app_vpc.id
  cidr_block        = var.cidr_block_private_subnet_app[count.index]
  count             = 2
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-${var.availability_zones[count.index]}"

  }
}

resource "aws_subnet" "main_app_private_subnet_data" {
  vpc_id            = aws_vpc.main_app_vpc.id
  cidr_block        = var.cidr_block_private_subnet_data[count.index]
  count             = 2
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-${var.availability_zones[count.index]}"

  }
}
resource "aws_nat_gateway" "main_app_nat_gw" {
  count         = 2
  allocation_id = aws_eip.main_app_eip[count.index].id
  subnet_id     = aws_subnet.main_app_public_subnet[count.index].id
  tags = {
    Name = "main_app_nat_gw"
  }
  depends_on = [aws_internet_gateway.main_app_igw]
}

resource "aws_eip" "main_app_eip" {
  count = 2
  tags = {
    Name = "main_app_eip"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_app_igw.id
  }

  tags = {
    Name = "public_route_table"
  }

}

resource "aws_route_table_association" "public_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.main_app_public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id

}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_app_vpc.id
  count  = 2

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_app_nat_gw[count.index].id
  }

}

resource "aws_route_table_association" "private_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.main_app_private_subnet_app[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id

}

resource "aws_db_subnet_group" "main_app_db_subnet_group" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for RDS database"
  subnet_ids  = aws_subnet.main_app_private_subnet_data[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_lb" "main_app_alb" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer.id]
  subnets            = aws_subnet.main_app_public_subnet[*].id

  tags = {
    Name = "${var.project_name}-lb"
  }

}

resource "aws_lb_listener" "main_app_lb_listener" {
  load_balancer_arn = aws_lb.main_app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_app_lb_target_group.arn

  }

}

resource "aws_lb_target_group" "main_app_lb_target_group" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_app_vpc.id

  health_check {
    path                = "/phpinfo.php"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }

}

