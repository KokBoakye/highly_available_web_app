data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "main_app_launch_template" {
  name_prefix   = "${var.project_name}-launch-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.webserver.id, aws_security_group.efs_clients.id, aws_security_group.database_clients.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash

# DB_NAME="workshopdb"
# DB_USERNAME="adminuser"
# DB_PASSWORD="ChangeMe123!"
# DB_HOST="workshop-db-instance.c1kogmiaevbz.eu-north-1.rds.amazonaws.com"
# EFS_FS_ID="fs-042f67eb976091ea4"

# Install AWS CLI v2 if not installed
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Fetch DB credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id workshop-db-credentials --query SecretString --output text)
DB_NAME=$(echo $DB_SECRET | jq -r .db_name)
DB_USERNAME=$(echo $DB_SECRET | jq -r .username)
DB_PASSWORD=$(echo $DB_SECRET | jq -r .password)
DB_HOST=$(echo $DB_SECRET | jq -r .host)

# EFS_FS_ID 
EFS_FS_ID="fs-042f67eb976091ea4"

dnf update -y

#install wget, apache server, php and efs utils
dnf install -y httpd wget php-fpm php-mysqli php-json php amazon-efs-utils

#create wp-content mountpoint
mkdir -p /var/www/html/wp-content
mount -t efs $EFS_FS_ID:/ /var/www/html/wp-content

#install wordpress
cd /var/www
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp wordpress/wp-config-sample.php wordpress/wp-config.php
rm -f latest.tar.gz

#change wp-config with DB details
cp -rn wordpress/* /var/www/html/
sed -i "s/database_name_here/$DB_NAME/g" /var/www/html/wp-config.php
sed -i "s/username_here/$DB_USERNAME/g" /var/www/html/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/g" /var/www/html/wp-config.php
sed -i "s/localhost/$DB_HOST/g" /var/www/html/wp-config.php

#change httpd.conf file to allowoverride
#  enable .htaccess files in Apache config using sed command
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# create phpinfo file
echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php

# Recursively change OWNER of directory /var/www and all its contents
chown -R apache:apache /var/www

systemctl restart httpd
systemctl enable httpd
EOF
  )


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-ec2-instance"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
}

resource "aws_autoscaling_group" "main_app_asg" {
  launch_template {
    id      = aws_launch_template.main_app_launch_template.id
    version = "$Latest"
  }

  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = aws_subnet.main_app_private_subnet_app[*].id
  health_check_type         = "EC2"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.main_app_lb_target_group.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

}
