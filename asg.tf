resource "aws_security_group" "asg_launch_template" {
  name = "asg_wordpress_sg"
  description = "Allow traffic to ASG"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = var.public_subnet_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = var.public_subnet_cidrs
  }


  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asg_wordpress_sg"
  }
}

resource "aws_launch_template" "wordpress" {
  name          = "wordpress_launch_template"
  image_id      = var.ami_id 
  instance_type = var.instance_type
  vpc_security_group_ids = [ aws_security_group.asg_launch_template.id ]

  user_data = base64encode(templatefile("./resources/user_data_ec2_wordpress.tpl",{
    DB_ENDPOINT = aws_db_instance.kbc_wordpress.endpoint
    DB_NAME = var.db_name
    DB_USER = var.db_username
    DB_PASSWORD = var.db_password
    WP_URL = aws_lb.alb.dns_name
    WP_TITLE = var.wp_title
    WP_ADMIN_USER = var.wp_admin_user
    WP_ADMIN_PASSWORD = var.wp_admin_password
    WP_ADMIN_EMAIL = var.wp_admin_email
  }))

  tags = {
    Name = "wordpress_launch_template"
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    instance_metadata_tags = "enabled"
    http_endpoint = "enabled"
    http_tokens = "required"
  }
}

resource "aws_autoscaling_group" "wordpress" {
  name = "wordpress-server-asg"
  min_size             = 1
  max_size             = 3
  vpc_zone_identifier  = aws_subnet.private_subnets[*].id
  target_group_arns = [aws_lb_target_group.alb_http.arn]

  launch_template {
    id = aws_launch_template.wordpress.id
    version = aws_launch_template.wordpress.latest_version
  }

  tag {
    key                 = "Name"
    value               = "wordpress-server"
    propagate_at_launch = true
  }

  instance_refresh {
      strategy = "Rolling"
      preferences {
        min_healthy_percentage = 50
      }
    }
  

  depends_on = [aws_db_instance.kbc_wordpress,aws_lb.alb]
}
resource "aws_autoscaling_policy" "per_request_scaling" {
  name                   = "per-request-scaling"
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup = 120
  autoscaling_group_name = aws_autoscaling_group.wordpress.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${aws_lb.alb.arn_suffix}/${aws_lb_target_group.alb_http.arn_suffix}"
    }
    target_value = 50.0
  }
}

resource "aws_sns_topic" "cpu_alerts" {
  name = "cpu_alerts"
}

resource "aws_sns_topic_subscription" "cpu_alerts_email" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = "iminchev24@gmail.com"
}

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "asg-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress.name
  }

  alarm_actions = [aws_sns_topic.cpu_alerts.arn]
  ok_actions    = [aws_sns_topic.cpu_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.cpu_alerts.arn]
}