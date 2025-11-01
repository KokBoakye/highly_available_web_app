# 🌐 WordPress Infrastructure — Terraform & Checkov

This repository provisions a **secure, scalable WordPress infrastructure** using **Terraform**.  
It’s designed for high availability, automated deployment, and continuous security validation through **Checkov**.

---

## 🗂️ Repository Structure

├── .github
│ └── workflows
│ └── deploy.yml # CI/CD pipeline for Terraform + Checkov
├── .gitignore # Excludes sensitive files and local configs
├── README.md # Project documentation
└── terraform
  ├── db.tf # Database configuration (Aurora / RDS)
  ├── ec2.tf # Launch Template & Auto Scaling Group
  ├── efs.tf # Shared file system (EFS)
  ├── main.tf # Root Terraform configuration
  ├── outputs.tf # Exposed outputs (endpoints, IDs, etc.)
  ├── provider.tf # Provider setup (region, credentials)
  ├── secrets.tf # Secrets Manager configuration
  ├── security.tf # Security groups and IAM roles
  ├── terraform.tfvars # Variable values (excluded from Git)
  └── variables.tf # Input variable definitions
  └── terraform.tfvars # Input variable definitions 

---

## 🌐 Architecture Overview

| Component | Purpose |
|------------|----------|
| **VPC** | Isolated network environment |
| **Subnets** | Six subnets across two Availability Zones (public, application, and database) |
| **Internet Gateway** | Provides internet access to public subnets |
| **NAT Gateways** | Allow private subnets to access the internet for updates |
| **Application Load Balancer (ALB)** | Distributes web traffic across EC2 instances |
| **Amazon EFS** | Shared file system for persistent WordPress content |
| **Amazon Aurora (MySQL)** | Highly available, managed database backend |
| **Auto Scaling Group (ASG)** | Dynamically scales EC2 web servers across AZs |

---

## 🧱 Create the VPC

1. Create a new VPC named **`wordpress-workshop`**
2. CIDR block: `10.0.0.0/16`
3. Enable DNS resolution and DNS hostnames

---

## 🌍 Create Subnets

Create six subnets across two Avaiility Zones (AZs):

| Type | AZ A | AZ B | Purpose |
|------|------|------|----------|
| Public | `10.0.0.0/24` | `10.0.1.0/24` | Load balancer, NAT gateways |
| Application | `10.0.2.0/24` | `10.0.3.0/24` | EC2, EFS |
| Database | `10.0.4.0/24` | `10.0.5.0/24` | RDS Aurora |

✅ Each subnet must have a **unique CIDR** and be associated with the same VPC.

---

## 🌐  Internet Gateway & Routing

1. **Internet Gateway (IGW):** Attach to the VPC.  
2. **Public Route Table:**  
   - Default route `0.0.0.0/0` → IGW  
   - Associate with public subnets.  
3. **NAT Gateways:** One per AZ inside public subnets.  
4. **Application Route Tables:**  
   - App A → NAT Gateway A  
   - App B → NAT Gateway B  
5. **Database Subnets:** No internet access.

---

## 🛡️  Database Setup (Aurora)

### Security Groups
- **WP Database SG** → for Aurora instances  
- **WP Database Clients SG** → for EC2 web servers  
- Allow inbound MySQL (port 3306) from `WP Database Clients SG`.

### RDS Subnet Group
- Name: `aurora-wordpress`  
- Subnets: Database Subnet A & B  
- VPC: `wordpress-workshop`

### Aurora Cluster Configuration
- Engine: **Aurora MySQL**
- Username: `wpadmin`
- Password: stored securely in **AWS Secrets Manager**
- DB Name: `wordpress`
- Instance class: `t4g.medium`
- Multi-AZ: Enabled
- Security Group: `WP Database SG`

✅ **Verify:**
- Cluster spans two AZs  
- Connections only allowed from EC2 instances via the SGs  

---

## 💾  Shared File System (EFS)

### Security Groups
- **WP EFS SG** → attached to EFS
- **WP EFS Clients SG** → attached to EC2
- Allow inbound TCP `2049` (NFS) from EFS Clients SG.

### Filesystem
- Name: `Wordpress-EFS`
- Mount targets: 1 per AZ (Application Subnets)
- Disable automatic backups for simplicity (keep enabled in production).

✅ **Verify:**
- Filesystem status: **Available**
- Mount targets exist in both AZs
- EC2 ↔ EFS SGs allow NFS communication

---

## ⚙️  Load Balancer (ALB)

### Security Groups
- **WP Load Balancer SG:**  
  - Inbound HTTP (80) from the internet  
- **WP Web Servers SG:**  
  - Inbound HTTP (80) from the Load Balancer SG  

### ALB Configuration
- Type: **Application Load Balancer (Layer 7)**
- Subnets: Public A & B
- Listener: HTTP port 80
- Target Group: `Wordpress-TargetGroup`
  - Health check path: `/phpinfo.php`

✅ **Verify:**
- ALB is Active  
- Target group created  
- Record ALB DNS name for WordPress access  

---

## 🧩  Launch Template (EC2 Configuration)

**Name:** `WP-WebServers-LT`  
**AMI:** Amazon Linux 2023  
**Instance Type:** `t3.micro`  
**Security Groups:**
- WP Web Servers
- WP Database Clients
- WP EFS Clients

### 📝 User Data Script

```bash
#!/bin/bash
DB_NAME="wordpress"
DB_USERNAME="wpadmin"
DB_PASSWORD="" # Fetch securely via Secrets Manager
DB_HOST="wordpress-workshop.cluster-xxxxxxxxxx.eu-west-1.rds.amazonaws.com"
EFS_FS_ID="fs-xxxxxxxxx"

dnf update -y
dnf install -y httpd wget php-fpm php-mysqli php-json php amazon-efs-utils

mkdir -p /var/www/html/wp-content
mount -t efs $EFS_FS_ID:/ /var/www/html/wp-content

cd /var/www
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp wordpress/wp-config-sample.php wordpress/wp-config.php
rm -f latest.tar.gz

cp -rn wordpress/* /var/www/html/
sed -i "s/database_name_here/$DB_NAME/g" /var/www/html/wp-config.php
sed -i "s/username_here/$DB_USERNAME/g" /var/www/html/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/g" /var/www/html/wp-config.php
sed -i "s/localhost/$DB_HOST/g" /var/www/html/wp-config.php

sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
chown -R apache:apache /var/www

systemctl restart httpd
systemctl enable httpd

✅ Behavior
Installs WordPress automatically
Connects to Aurora DB
Mounts EFS
Configures Apache


🚀  Auto Scaling Group
Configuration
Launch Template: WP-WebServers-LT
Subnets: Application A & B
Target Group: Wordpress-TargetGroup
Health Checks: ELB
Scaling:
Desired: 2
Min: 2
Max: 4
Policy: Target tracking (CPU ≥ 80%)
✅ Verify
Instances launch across AZs
Targets become healthy under ALB
Access WordPress via the ALB DNS
✅ Final Outcome
You now have a highly available WordPress platform with:
Multi-AZ resilience
Auto scaling web tier
Shared EFS storage
Secure Aurora backend
Layer-7 load balancing
🔒 Security Practices
No hardcoded secrets — use AWS Secrets Manager
Terraform variables marked sensitive = true
.tfvars excluded in .gitignore
IAM roles grant least privilege to EC2 and RDS


🧮 Infrastructure Security Scan (Checkov)
This project integrates Checkov — an open-source static analysis tool for Terraform and AWS security best practices.
Run Scan

Example Output
A report is generated after each deployment to identify misconfigurations, policy violations, and non-compliance issues.

Uploaded Results
The latest scan results are available in:
checkov-reports/
├── checkov_summary.json

✅ Status:
All critical and high-severity findings resolved.
Remaining informational items are tracked for improvement.


🧾 Notes
Use environment variables or CI/CD secrets for credentials.
Apply IAM least-privilege principles.
Use Terraform workspaces or variables for multi-region deployment.
Keep Checkov scans automated in CI pipelines.


🏁 Conclusion
This workshop demonstrates end-to-end WordPress deployment automation on AWS using Terraform and DevSecOps best practices.
“Infrastructure as Code done right — secure, scalable, and reproducible.”


Author: Kwabena Okyere Boakye
