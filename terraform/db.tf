resource "aws_db_instance" "db_instance" {
  identifier             = "${var.project_name}-db-instance"
  allocated_storage      = var.db_allocated_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main_app_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database.id]
  skip_final_snapshot    = true
  multi_az               = true

  tags = {
    Name = "${var.project_name}-db-instance"
  }

}
