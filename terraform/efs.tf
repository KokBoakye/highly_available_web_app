resource "aws_efs_file_system" "main_app_efs" {
  creation_token = "${var.project_name}-efs"
  tags = {
    Name = "${var.project_name}-efs"
  }

}

resource "aws_efs_mount_target" "main_app_efs_mount_target" {
  count          = 2
  file_system_id = aws_efs_file_system.main_app_efs.id
  subnet_id      = aws_subnet.main_app_private_subnet_data[count.index].id
  security_groups = [
    aws_security_group.efs.id,
  ]

}
