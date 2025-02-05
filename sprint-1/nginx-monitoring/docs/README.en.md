[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# Automated nginx Monitoring

## About the Project

This project consists on creating an Amazon EC2 instance with Ubuntu Server 24.04 LTS to set up an nginx server, monitor the service status through a custom script, and automate its execution every 5 minutes. The script records the date, time, service name, status, and a custom ONLINE or OFFLINE message, enabling monitoring of service continuity and availability.

### Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Virtual Environment Configuration](#2-virtual-environment-configuration)
    - 2.1 [Resource Configuration](#21-resource-configuration)
    - 2.2 [VPC Creation](#22-vpc-creation)
3. [EC2 Instance Configuration and Creation](#3-ec2-instance-configuration-and-creation)
    - 3.1 [Security Group Configuration](#31-security-group-configuration)
    - 3.2 [Instance Creation](#32-instance-creation)
    - 3.3 [Elastic IP Allocation](#33-elastic-ip-allocation)
4. [Connecting to the Instance](#4-connecting-to-the-instance)
    - 4.1 [SSH Key Configuration](#41-ssh-key-configuration)
    - 4.2 [SSH Connection](#42-ssh-connection)
5. [nginx Installation and Configuration](#5-nginx-installation-and-configuration)
6. [Monitoring Script Creation](#6-monitoring-script-creation)
   - 6.1 [Log Directory Configuration](#61-log-directory-configuration)
   - 6.2 [Script Creation](#62-script-creation)
7. [Script Automation](#7-script-automation)
   - 7.1 [Validating Script Automation](#71-validating-script-automation)
8. [References](#8-references)

## 1. Prerequisites

- An active AWS account
- Basic knowledge of the AWS console
- Basic Linux terminal knowledge

## 2. Virtual Environment Configuration 

Before creating our EC2 instance, we need to configure the network environment where it will run. We'll create a VPC (Virtual Private Cloud) dedicated to the project.

> [!NOTE]
> AWS offers two options for VPC creation: manual and automatic. In manual creation, you configure the VPC, subnets, routers, gateways, and other network options customly. In the automatic option, the **VPC wizard** creates the VPC with public and private subnets, attaches an internet gateway, configures route tables, and includes a NAT gateway if necessary. We'll use automatic creation with the VPC wizard.

### 2.1 Resource Configuration

1. In the AWS console, access the VPC service and click "**Create VPC**".

2. In "**Name tag auto-generation**", keep it checked to generate names automatically.

3. In the input field, enter the tag you want to use as a prefix for the resources that will be created.

4. Configure the resources:

    - VPC CIDR: 10.0.0.0/24 (provides 256 IP addresses, enough for the project)
    - Number of Availability Zones (AZs): 1
    - Number of public subnets: 1
    - Number of private subnets: 0
    - NAT Gateway: None
    - VPC endpoints: None

5. Optionally, add descriptive tags to the VPC. This helps easily identify resources associated with the project.

## 2.2 VPC Creation

1. Click "**Create VPC**" and wait for the resources to be created.

2. The wizard will automatically create:

    - A VPC with DNS hostnames enabled
    - A public subnet in the selected AZ
    - An internet gateway attached to the VPC
    - A route table configured with a route to the internet gateway
    - A default security group

#### VPC Workflow Preview

![VPC Workflow](../imgs/nginx-vpc-workflow.png)

## 3. EC2 Instance Configuration and Creation

We'll create an EC2 instance using an Ubuntu Server 24.04 LTS AMI and configure an Elastic IP to ensure a consistent address for the nginx server on the instance. Additionally, we'll configure specific inbound and outbound rules in the instance's security group. The SSH port (22) will be limited to your IP only to ensure secure instance access, and the HTTP port (80) will be opened to any IP (0.0.0.0/0) so the nginx server is publicly accessible. Finally, we'll keep outbound traffic unrestricted to allow the server to download updates and necessary packages during nginx installation and operation.

### 3.1 Security Group Configuration

1. In the services tab, click "**EC2**".

2. In the EC2 dashboard, under "**Network & Security**", click "**Security Groups**".

3. Locate the security group created by your VPC (look for the security group associated with your VPC ID in the information panel), and click on it to edit.

4. Click edit inbound rules.

5. Add a rule for **SSH**:

    - Type: SSH
    - Port: 22
    - Source type: your IP address (use "**My IP**" to add automatically)

6. Add a rule for "**HTTP**":

    - Type: HTTP
    - Port: 80
    - Source type: Anywhere-IPv4 (0.0.0.0/0)

7. Check outbound rules:

    - Keep the default rule that allows all traffic (0.0.0.0/0)

### 3.2 Instance Creation

1. On the EC2 main page, click "**Launch Instance**".

2. General instance settings:

    - Create descriptive tags associated with the project to facilitate instance management in the future.

    - Select the **Ubuntu Server 24.04 LTS** AMI.

    - For **instance type**, select **t2.micro**. For the project's use case, t2.micro resources will be sufficient. Additionally, it's included in AWS's free tier.

    - Create a key pair or select an existing one. They will be necessary to access the instance via SSH.

3. Instance network settings:

    - In "**VPC**", select the VPC created earlier for the project.

    - In "**subnet**", select the subnet created with the VPC.

    - Enable **auto-assign public IP**.

    - In "**Common security groups**", select the security group created with the VPC.

4. Keep default storage settings.

5. Review the settings. If everything is correct, click "**Launch instance**".

### 3.3 Elastic IP Allocation

1. In the EC2 dashboard, under "**Network & Security**", navigate to "**Elastic IPs**".

2. Click "**Allocate Elastic IP address**".

3. Use Amazon's IPv4 address pool.

4. If desired, add descriptive tags associated with the project.

5. Once created, select the IP, click "**Actions**" and "**Associate Elastic IP address**".

6. Select the server instance.

7. Click "**Associate**".

## 4. Connecting to the Instance

First, we'll adjust the private key permissions. Then, we'll use this key to establish a secure SSH connection with the instance.

### 4.1 SSH Key Configuration

1. Use the following command to set your private key file permissions so only you can read it:

   ```bash
   chmod 400 ~/path/to/key.pem
   ```

> [!IMPORTANT]
> If you don't set these permissions, you won't be able to connect to your instance using this key pair, as the SSH client will reject the key for security reasons.

### 4.2 SSH Connection

1. Open the terminal on your computer and use the `ssh` command to connect to your instance. You'll need the private key location (.pem file), username, and your public DNS, as in the example below:

```bash
ssh -i ~/path/to/key.pem ubuntu@your-public-dns
```

2. The first time you connect, you'll see a fingerprint warning. Accept by typing "yes" to confirm you're connecting to the correct server and save it for future secure connections. After connecting, some information about the Ubuntu distribution will be displayed, and the shell prompt should be something like:

```bash
ubuntu@ip-10-0-0-xx:~$
```

## 5. nginx Installation and Configuration

1. Open the Ubuntu terminal and run the following command to ensure the correct package installation and its latest version:

```bash
sudo apt update && sudo apt upgrade -y
```

2. Install nginx:

```bash
sudo apt install nginx -y
```

3. Check nginx status:

```bash
sudo systemctl status nginx
```

4. If nginx is running correctly, the command will return an output like this:

![Active nginx Status](../imgs/nginx_active_status.png)

5. To ensure nginx starts automatically after instance reboot, use the command:

```bash
sudo systemctl enable nginx
```

6. To verify if the server is working, open the browser and type the instance's Elastic IP in the address bar. If everything is correct, the server should show the default nginx page:

![nginx Default Homepage](../imgs/nginx_default_homepage.png)

## 6. Monitoring Script Creation

### 6.1 Log Directory Configuration

1. Before creating the script, we'll create the directory where nginx monitoring logs will be stored:

```bash
sudo mkdir /var/log/nginx_status
```

2. Change the directory ownership to your user:

```bash
sudo chown ubuntu:ubuntu /var/log/nginx_status
```

3. Adjust permissions:

```bash
sudo chmod 755 /var/log/nginx_status
```

This configuration ensures you have full access to the directory, while other users can only read and execute files within it.

### 6.2 Script Creation

We'll store the script inside the `/usr/local/bin` directory. This directory is already included in the PATH by default, allowing script execution from anywhere without needing to specify the full path.

1. To create and edit the script, use a text editor. Using `nano`:

```bash
sudo nano /usr/local/bin/nginx_status_monitor.sh
```

2. Type the script:

```bash
#!/usr/bin/env bash

# gets current date and time
date_time=$(date "+%d-%m-%Y %H:%M:%S")

# service name
service="nginx"

# service status
status=$(systemctl is-active $service)

# paths to log files
log_online="/var/log/nginx_status/nginx_online.log"
log_offline="/var/log/nginx_status/nginx_offline.log"

# checks nginx service status and writes to log files
if [ "$status" = "active" ]; then
    echo "Date and Time: $date_time | Service: $service | Status: $status | Service $service is ONLINE." >> "$log_online"
else
    echo "Date and Time: $date_time | Service: $service | Status: $status | Service $service is OFFLINE" >> "$log_offline"
fi
```

3. Press `CTRL + O` and `ENTER` to save and `CTRL + X` to exit. After that, grant execution permission to the script so you can run it:

```bash
sudo chmod +x /usr/local/bin/nginx_status_monitor.sh
```

4. To verify if it's working correctly, run the script manually:

```bash
nginx_status_monitor.sh
```

5. Then, check the corresponding log files. Example of the `nginx_online.log` file with active service logs:

![Manual Online Log Entry](compass-devsecops-scholarship/sprint-1/nginx-monitoring/mgs/manual_online_log_entry.png)

## 7. Script Automation

To automate script execution, we'll use the **cron** service. Cron is an operating system service responsible for scheduling and executing tasks automatically at defined intervals. It uses the **crontab** file to store task configurations, which can be executed at specific times.

1. To automate our script, run the following command to open and edit the crontab:

```bash
crontab -e
```

2. Select a text editor. Add the following line to the file:

```bash
*/5 * * * * /usr/local/bin/nginx_status_monitor.sh
```

3. Save and exit the file.

Cron configuration files have five fields to specify time and date, followed by the command to be executed. Each of these five fields is separated by a space and there can't be spaces within each field. They are:

- Minute (0-59)
- Hour (0-23, where 0 = midnight)
- Day of month (1-31)
- Month (1-12)
- Day of week (0-6, where 0 = Sunday)

An asterisk (*) can be used to indicate that all occurrences (all hours, all days of the week, all months, etc.) of a time period should be considered.

Therefore, in our case, the expression */5 * * * * makes the script run every 5 minutes, regardless of the hour, day of month, month, or day of the week.

### 7.1 Validating Script Automation

After saving the configurations in crontab, script execution will start automatically every five minutes.

1. We can check the list of scheduled tasks in cron with the following command:

    ```bash
    crontab -l
    ```

    1.1 The command should return the previously configured task as in the following image:

    ![Crontab -l Output](../imgs/crontab-l.png)

Example of log file outputs with the service online:

![Cron Online Logs](../imgs/nginx_online_log_entry.png)

Example of log file outputs with the service offline:

![Cron Offline Logs](../imgs/nginx_offline_log_entry.png)

## 8. References

- [Amazon Virtual Private Cloud (VPC) Documentation](https://docs.aws.amazon.com/vpc/?icmpid=docs_homepage_featuredsvcs)
- [Amazon Elastic Compute Cloud (Amazon EC2) Documentation](https://docs.aws.amazon.com/ec2/?icmpid=docs_homepage_featuredsvcs)
- [nginx Documentation](https://nginx.org/en/docs/)
- [Cron Jobs Configuration and Usage Guide](https://www.pantz.org/software/cron/croninfo)