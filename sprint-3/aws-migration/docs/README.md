[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# **Migração e Modernização na AWS: De Lift-and-Shift ao Kubernetes com MGN e DMS**

## Sobre o Projeto

A **"Fast Engineering S/A"** está em um processo de modernização de sua infraestrutura de eCommerce, visando uma migração para a AWS. A solução atual não atende mais à alta demanda de acessos e compras, e por isso, a empresa está adotando uma abordagem de migração em duas fases:

1. **Migração "Lift-and-Shift" (as-is)**: Essa fase inicial tem como objetivo a rápida migração dos sistemas para a AWS, sem mudanças significativas na arquitetura, garantindo que a infraestrutura atenda a demanda crescente de forma imediata. Para isso, será utilizado o **AWS MGN (Application Migration Service)** para a migração dos servidores, enquanto o **AWS DMS (Database Migration Service)** será responsável pela migração do banco de dados de forma eficiente e com o mínimo de downtime.
  
2. **Modernização para o Kubernetes**: Após a migração, a infraestrutura será modernizada para um ambiente baseado em Kubernetes, utilizando o **Amazon EKS (Elastic Kubernetes Service)**. O **EKS** oferece uma solução totalmente gerenciada para execução de clusters Kubernetes, permitindo maior escalabilidade, disponibilidade e facilidade de gerenciamento. 

A nova arquitetura será planejada para atender as seguintes diretrizes:

- **Ambiente Kubernetes** para gerenciamento eficiente de containers.
- **Banco de dados gerenciado** (PaaS, Multi-AZ) para garantir alta disponibilidade e escalabilidade.
- **Backup de dados** para proteção e recuperação.
- **Sistema de persistência de objetos** (como imagens, vídeos, etc.) para armazenamento escalável e durável.
- **Segurança** aprimorada para proteger os dados e a infraestrutura.

### Índice 

1. [Arquitetura Atual](#1-arquitetura-atual)