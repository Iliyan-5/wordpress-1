resource "aws_iam_role" "rds_iam_role"{
  name = "rds-iam-role"
  assume_role_policy = templatefile("policies/rds_assume_role_policy.json",{})
}

resource "aws_iam_policy" "rds_iam_policy" {
  name = "rds-iam-policy"
  policy = templatefile("policies/rds_iam_policy.json",{})
}

resource "aws_iam_role_policy_attachment" "rds_role_attachment" {
  policy_arn = aws_iam_policy.rds_iam_policy.arn
  role       = aws_iam_role.rds_iam_role.name
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
    #security_groups = [aws_security_group.asg_launch_template.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "main-subnet-group"
  }
}

resource "aws_db_instance" "kbc_wordpress" {
  identifier = "kbc-wordpress-database" 
  allocated_storage    = var.db_allocated_storage
  max_allocated_storage = var. max_allocated_storage
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  multi_az             = true
  storage_type         = "gp2"
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  auto_minor_version_upgrade = false
  skip_final_snapshot = true
  monitoring_interval  = 60
  monitoring_role_arn  = aws_iam_role.rds_iam_role.arn

  tags = {
    Name = "kbc-wordpress-database"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "rds-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.kbc_wordpress.id
  }

  alarm_actions = [aws_sns_topic.cpu_alerts.arn]
  ok_actions    = [aws_sns_topic.cpu_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.cpu_alerts.arn]
}