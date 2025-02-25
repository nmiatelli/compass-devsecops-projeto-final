[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# **AWS Migration & Modernization: Lift-and-Shift to Kubernetes with AWS MGN and DMS**

## About the Project

**Fast Engineering S/A** is in the process of modernizing its eCommerce infrastructure with a migration to AWS. The current system can no longer handle the high traffic and volume of purchases, so the company is taking a two-phase approach:

1. **Lift-and-Shift Migration (as-is):** In this initial phase, the focus is on quickly moving the systems to AWS without major architectural changes, ensuring that the infrastructure can immediately meet growing demand. To accomplish this, **AWS MGN (Application Migration Service)** will be used for server migration, while **AWS DMS (Database Migration Service)** will handle the database migration efficiently and with minimal downtime.

2. **Modernization to Kubernetes:** Once the migration is complete, the infrastructure will be updated to a Kubernetes-based environment using **Amazon EKS (Elastic Kubernetes Service)**. EKS offers a fully managed solution for running Kubernetes clusters, enabling enhanced scalability, availability, and easier management.

The new architecture is designed with the following key principles in mind:

- A **Kubernetes environment** for efficient container management.
- A **managed database** (PaaS, Multi-AZ) to ensure high availability and scalability.
- **Data backups** for protection and recovery.
- An **object storage system** (for assets like images, videos, etc.) for scalable and durable storage.
- Enhanced **security** measures to protect both data and infrastructure.