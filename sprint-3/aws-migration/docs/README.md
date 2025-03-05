[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# **Migração e Modernização na AWS: De Lift-and-Shift ao Kubernetes com MGN e DMS**

## Sobre o Projeto

A **Fast Engineering S/A** está em um processo de modernização de sua infraestrutura de eCommerce, visando uma migração para a AWS. A solução atual não atende mais à alta demanda de acessos e compras, e por isso, a empresa está adotando uma abordagem de migração em duas fases:

1. **Migração "Lift-and-Shift" (as-is)**: Esta fase inicial tem como objetivo a rápida migração dos sistemas para a AWS, sem mudanças significativas na arquitetura, garantindo que a infraestrutura atenda a demanda crescente de forma imediata. Para isso, utilizamos o **AWS MGN (Application Migration Service)** para a migração dos servidores, enquanto o **AWS DMS (Database Migration Service)** será responsável pela migração do banco de dados de forma eficiente e com o mínimo de downtime.
  
2. **Modernização para o Kubernetes**: Após a migração, a infraestrutura será modernizada para um ambiente baseado em Kubernetes, utilizando o **Amazon EKS (Elastic Kubernetes Service)**. O **EKS** oferece uma solução totalmente gerenciada para execução de clusters Kubernetes, permitindo maior escalabilidade, disponibilidade e facilidade de gerenciamento. 

A nova arquitetura será planejada para atender as seguintes diretrizes:

- **Ambiente Kubernetes** para gerenciamento eficiente de containers.
- **Banco de dados gerenciado** (PaaS, Multi-AZ) para garantir alta disponibilidade e escalabilidade.
- **Backup de dados** para proteção e recuperação.
- **Sistema de persistência de objetos** (como imagens, vídeos, etc.) para armazenamento escalável e durável.
- **Segurança** aprimorada para proteger os dados e a infraestrutura.

### Índice 

1. [Arquitetura Atual](#1-arquitetura-atual)
    - 1.1 [Visão Geral da Arquitetura](#11-visão-geral-da-arquitetura)
    - 1.2 [Infraestrutura dos Servidores](#12-infraestrutura-dos-servidores)
    - 1.3 [Diagrama da Arquitetura Atual](#13-diagrama-da-arquitetura-atual)
2. [Arquitetura Proposta](#2-arquitetura-proposta)
    - 2.1 [Etapa 1: Lift-and-Shift (As-Is)](#21-etapa-1-lift-and-shift-as-is)
        - 2.1.1 [Diagrama](#211-diagrama)

### 1.1 Visão Geral da Arquitetura
O sistema atual utiliza uma arquitetura de três camadas com servidores separados para banco de dados, frontend e funções do backend. O Nginx no servidor do backend atua como balanceador de carga para as três APIs e serve conteúdo estático, enquanto o frontend em React e o banco de dados MySQL operam em servidores dedicados.

## 1.2 Infraestrutura dos Servidores

### Servidor do Banco de Dados

- **Finalidade**: Servidor de Banco de Dados MySQL
- **Armazenamento**: 500GB de dados
- **Memória**: 10GB RAM
- **Processamento**: 3 Cores

### Servidor do Frontend

- **Finalidade**: Aplicação React
- **Armazenamento**: 5GB de dados
- **Memória**: 2GB RAM
- **Processamento**: 1 Core

### Servidor do Backend

- **Finalidade**: APIs de Backend com Balanceador de Carga Nginx
- **Componentes**:
  - 3 APIs
  - Nginx
  - Armazenamento de arquivos estáticos
- **Armazenamento**: 5GB de dados
- **Memória**: 4GB RAM
- **Processamento**: 2 Cores

## 1.3 Diagrama da Arquitetura Atual

![Diagrama da Arquitetura Atual](../imgs/arqatualfasteng.png)

## 2. Arquitetura Proposta

### 2.1 Etapa 1: Lift-and-Shift (As-Is)

Nesta primeira etapa, utilizamos o **Application Migration Service** para migrar os servidores do ambiente on-premises para a AWS de forma eficiente e com o mínimo de downtime, sem alterações significativas na infraestrutura.

#### Servidores de Origem

Como primeiro passo, é essencial a instalação de um **agente de replicação** nos servidores on-premises. Para isso, criamos um usuário do IAM na AWS com as permissões necessárias para interagir com os recursos da AWS e permitir a replicação dos dados a partir dos servidores de origem para a nuvem.

#### Servidores de Replicação

Neste passo, servidores de replicação são provisionados automaticamente pelo AWS MGN com base em um modelo de configuração de replicação. No nosso caso, o Replication Settings Template define os parâmetros necessários para a configuração, incluindo a subnet privada, o acesso à internet via NAT Gateway e as regras de firewall para a conectividade com os servidores on-premises. Estes servidores são responsáveis por armazenar temporariamente e processar os dados dos servidores on-premises antes de enviá-los à **staging area**.

#### Staging Area 

Após a replicação dos dados para o servidor de replicação, os dados são enviados para a staging area na AWS, no nosso caso consistindo em um volume EBS. Nesta área, os dados são armazenados temporariamente e preparados para a conversão final. Durante este processo, são realizadas verificações, como a validação da integridade dos dados replicados, a verificação de consistência entre os dados on-premises e os dados na staging area, e ajustes de configuração necessários, como a adaptação de caminhos de diretórios, parâmetros de rede, permissões ou outras configurações específicas de software. Além disso, testes de desempenho são realizados para garantir que a infraestrutura da AWS seja capaz de lidar com o volume de dados. Uma vez validados e ajustados, os dados estão prontos para serem transformados em instâncias EC2 na AWS.

#### Conversão e Lançamento das Instâncias EC2

Após a preparação e validação dos dados na staging area, os dados são convertidos em instâncias EC2 na AWS. Este processo transforma os volumes EBS que contêm os dados replicados em volumes de armazenamento anexados a instâncias EC2 configuradas de acordo com as necessidades do ambiente. As instâncias EC2 são então configuradas com a infraestrutura necessária, incluindo:

  - **Configuração de rede:** As instâncias são colocadas em subnets privadas com regras de segurança definidas nos Security Groups e Network ACLs.
  - **Balanceamento de carga:** Um **Application Load Balancer** é configurado para distribuir o tráfego de forma eficiente entre as instâncias EC2, garantindo alta disponibilidade.
  - **Auto Scaling:** As instâncias EC2 são configuradas em um **Auto Scaling Group** para permitir a escalabilidade automática com base na demanda de tráfego.
  - **DNS:** O **Amazon Route 53** é configurado para gerenciar o DNS, direcionando o tráfego para as instâncias EC2 de forma eficiente.

#### Testes

Nesta etapa, realizamos testes para garantir que tudo está funcionando como esperado. As instâncias migradas são avaliadas em um ambiente de pré-produção na AWS, sem afetar o ambiente de produção original. Isso permite verificar a funcionalidade e a acessibilidade dos dados, além de identificar e corrigir possíveis problemas. Aqui, são realizados os seguintes testes:

  - **Verificação de dados:** Verificar se os dados foram replicados corretamente e estão acessíveis de forma adequada.
  **Validação de desempenho:** Avaliar o desempenho das instâncias na AWS e compará-lo com o ambiente on-premises para garantir que os requisitos de capacidade estão sendo atendidos.
  - **Testes de aplicação:** Validar se as aplicações estão funcionando como esperado (exemplo: frontend se comunica com backend, APIs estão funcionando, etc.).
  - **Testes de integração:** Verificar se os diferentes componentes do sistema (exemplo: backend, banco de dados, load balancing) estão funcionando corretamente em conjunto.

#### Cutover

O cutover é a etapa final, onde a infraestrutura na AWS é oficialmente colocada em produção. Após os testes bem-sucedidos, a migração é finalizada, e a produção no ambiente local é desativada em favor do novo ambiente na nuvem. Isso envolve:

  - **Reconfiguração do DNS e redirecionamento de tráfego:** Alterar as configurações do DNS (através do Route 53) para apontar para a infraestrutura AWS em vez da infraestrutura local.
  - **Desativação de sistemas locais:** Após a validação final, os servidores on-premises podem ser desativados ou mantidos como redundantes, caso seja necessário um plano de contingência.
  - **Monitoramento pós-cutover:** Após o cutover, um período de monitoramento é essencial para garantir que o ambiente na AWS esteja funcionando como esperado e para detectar problemas logo no início.

Neste ponto, o processo de lift-and-shift é concluído e as instâncias estão operando na nuvem com a infraestrutura de suporte configurada para garantir alta disponibilidade, escalabilidade e segurança.