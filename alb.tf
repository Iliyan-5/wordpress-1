resource "aws_security_group" "alb_sg" {
  name = "alb_sg"
  description = "Allow traffic to ALB"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

resource "aws_lb" "alb" {
  name = "alb-wordpress"
  load_balancer_type = "application"
  internal = false
  security_groups = [aws_security_group.alb_sg.id]
  enable_cross_zone_load_balancing = true
  subnets = aws_subnet.public_subnets[*].id

  tags = {
    Name = "alb_wordpress"
  }
}

resource "aws_lb_target_group" "alb_http" {
  name = "alb-http"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "alb_http" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb_http.arn
    }
}
