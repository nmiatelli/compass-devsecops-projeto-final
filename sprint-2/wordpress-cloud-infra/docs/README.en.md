[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# High-Availabilty WordPress AWS Hosting System

## About the Project

This project consists on implementing a scalable infrastructure to host a WordPress application on AWS. The solution involves the installation and configuration of Docker on two EC2 instances, using a startup script (`user_data.sh`) to automate the process. Additionally, the project includes setting up a MySQL database managed by Amazon RDS, integrating Amazon EFS for WordPress static file storage, and deploying an Application Load Balancer to distribute traffic across instances in multiple Availability Zones, ensuring high availability. The EC2 instances are managed by an Auto Scaling Group, which automatically adjusts capacity based on demand, ensuring the application scales efficiently and remains available even during traffic spikes.

### Table of Contents

1. [Prerequisites](#1-prerequisites)