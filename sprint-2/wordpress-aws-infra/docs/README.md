[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# Sistema de Alta Disponibilidade de Hospedagem do WordPress

## Sobre o Projeto

Esse projeto consiste na implementação de uma infraestrutura escalável para hospedar aplicações WordPress na AWS. A solução envolve a instalação e configuração do Docker em instâncias EC2, utilizando um script de inicialização para automatizar o processo. Além disso, o projeto inclui a configuração de um banco de dados MySQL gerenciado pelo Amazon RDS, a integração do Amazon EFS para o compartilhamento de arquivos entre as instâncias EC2 que hospedam o WordPress e a implementação de um Application Load Balancer para distribuir o tráfego entre instâncias em múltiplas Zonas de Disponibilidade, garantindo alta disponibilidade. As instâncias EC2 são gerenciadas por um Auto Scaling Group, que ajusta automaticamente a capacidade com base na demanda, assegurando que a aplicação escale de forma eficiente e permaneça disponível mesmo em picos de tráfego.

### Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Configuração do Ambiente Virtual](#2-configuração-do-ambiente-virtual)
    - 2.1 [Configurações Gerais](#21-configurações-gerais)
    - 2.2 [Criação da VPC](#22-criação-da-vpc)
3. [Configuração dos Grupos de Segurança](#3-configuração-dos-grupos-de-segurança)
    - 3.1 [Criação dos Grupos de Segurança](#31-criação-dos-grupos-de-segurança)
    - 3.2 [Configuração das Regras de Entrada e Saída](#32-configuração-das-regras-de-entrada-e-saída)
4. [Configuração do Elastic File System (EFS)](#4-configuração-do-elastic-file-system-efs)
    - 4.1 [Configurações Gerais](#41-configurações-gerais)
    - 4.2 [Configurações de Rede](#42-configurações-de-rede)
    - 4.3 [Política do Sistema de Arquivos](#43-política-do-sistema-de-arquivos)
    - 4.4 [Revisão das Configurações](#44-revisão-das-configurações)
5. [Configurações do Relational Database Service (RDS)](#5-configuração-do-relational-database-service-rds)
    - 5.1 [Configurações Gerais](#51-configurações-gerais)
    - 5.2 [Configurações de Rede](#52-configurações-de-rede)
    - 5.3 [Configurações de Autenticação](#53-configurações-de-autenticação)
    - 5.4 [Configurações Adicionais](#54-configurações-adicionais)
6. [Configuração do Application Load Balancer](#6-configuração-do-application-load-balancer)
    - 6.1 []()
    

## 1. Pré-requisitos

- Uma conta ativa na AWS
- Conhecimento básico do console AWS
- Conhecimento básico do terminal Linux
- Familiaridade com conceitos de conteinerização

## 2. Configuração do Ambiente Virtual 

Antes de criarmos as instâncias EC2 que hospedarão as aplicações do WordPress e configurar os demais serviços de segurança, armazenamento e balanceamento de carga, precisamos configurar o ambiente de rede onde o projeto será executado. Criaremos uma VPC (Virtual Private Cloud) dedicada ao projeto.

> [!NOTE]
> A AWS oferece duas opções para criação de VPC: manual e automática. Na criação manual,  você configura a VPC, sub-redes, roteadores, gateways e outras opções de rede de forma  personalizada. Já na opção automática, o **assistente de VPC** cria a VPC com sub-redes públicas e  privadas, já anexa um gateway de internet, configura as tabelas de rotas e inclui um gateway NAT, caso seja necessário. Utilizaremos a criação automática com o VPC wizard. 

### 2.1 Configuração Gerais
 
1. No console AWS, acesse o serviço VPC e clique em "**Criar VPC**".

2. Em "**Configurações da VPC**" selecione "**VPC e muito mais**"

3. Em "**Geração automática de etiqueta de nome**", deixe marcado para gerar os nomes automaticamente.

4. No campo de entrada, digite a etiqueta que deseja utilizar como prefixo para o nome dos recursos que serão criados.

5. Configure os recursos:

    - CIDR da VPC: 10.0.0.0/16
    - Número de zonas de disponibilidade (AZs): 2
    - Número de sub-redes públicas: 2
    - Número de sub-redes privadas: 4 
    - Gateway NAT: 1 por AZ
    - VPC endpoints: Nenhuma 

6. Opcionalmente, adicione tags descritivas à VPC. Isso ajuda a identificar facilmente os recursos associados ao projeto.

## 2.2 Criação da VPC 

1. Clique em "**Criar VPC**" e aguarde a criação dos recursos.

2. O assistente criará automaticamente:

    - Uma VPC com DNS hostnames habilitados
    - Duas sub-redes públicas, um em cada Zona de Disponibilidade (AZ) selecionada
    - Duas sub-redes privadas, um em cada AZ selecionada, para os servidores das aplicações e armazenamento do banco de dados
    - Um Internet Gateway (IGW) anexado à VPC 
    - Dois NAT Gateways, um em cada sub-rede pública, para permitir acesso à internet para as sub-redes privadas
    - Tabelas de rota configuradas para:

        - sub-redes públicas com rotas para o Internet Gateway
        - sub-redes privadas com rotas para os respectivos NAT Gateways

    - Um grupo de segurança padrão

    #### Preview do VPC Workflow

![VPC Workflow](../imgs/vpc-workflow-ptbr.png)

## 3. Configuração dos Grupos de Segurança

Como cada recurso exige regras de tráfego distintas, criaremos grupos de segurança específicos para cada um deles, de modo a separar as responsabilidades, facilitar o gerenciamento e aumentar a segurança.

### 3.1 Criação dos Grupos de Segurança

> [!IMPORTANT]
> Nesse primeiro momento, criaremos apenas os grupos de segurança, sem nenhuma regra de tráfego. Isso é necessário porque alguns grupos de segurança precisarão referenciar outros em suas regras de entrada ou saída em etapas futuras.

No **Painel da VPC**, navegue até a seção "**Segurança**" e clique em "**Grupos de segurança**". Após isso, clique em "**Criar grupo de segurança**".

Criaremos um grupo de segurança para o balanceador de carga, as instâncias EC2, o EFS e o RDS. Para cada grupo de segurança, preencheremos:

- Nome do grupo de segurança 
- Descrição
- ID da VPC (selecione a VPC criada para o projeto)

### 3.2 Configuração das Regras de Entrada e Saída

Após criados os grupos de segurança, daremos sequência à configuração das regras de entrada e saída de cada um deles.

#### 3.3 Grupo de Segurança do Application Load Balancer (ALB)

1. Selecione o grupo de segurança do ALB, clique em "**Ações**" e "**Editar regras de entrada**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**".

3. Adicione uma regra para o **HTTP**:

    - Tipo: HTTP
    - Porta: 80
    - Tipo de origem: qualquer local-ipv4 (0.0.0.0/0)

4. Clique em "**Salvar regras**".

5. Selecione o grupo de segurança do ALB novamente, clique em "**Ações**" e "**Editar regras de saída**".

6. Verifique as "**Regras de saída**":

7. Como o ALB já encaminha o tráfego para as instâncias EC2 via **grupos de destino**, não é necessário configurar regras de saída

#### 3.4 Grupo de Segurança das Instâncias EC2

1. Selecione o grupo de segurança das instâncias EC2, clique em "**Ações**" e "**Editar regras de entrada**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**".

3. Adicione uma regra para o **HTTP**:

    - Tipo: HTTP
    - Porta: 80
    - Tipo de origem: selecione o **grupo de segurança do ALB**

4. Adicione uma regra para o **SSH**:

    - Tipo: SSH
    - Porta: 22
    - Tipo de origem: seu endereço de IP (use "**Meu IP**" para adicionar automaticamente)

5. Adicione uma regra para o **NFS**:

    - Tipo: NFS
    - Porta: 2049
    - Tipo de origem: selecione o **grupo de segurança do EFS**

6. Clique em "**Salvar regras**".

7. Selecione o grupo de segurança das instâncias EC2 novamente, clique em "**Ações**" e "**Editar regras de saída**".

8. Em "**regras de saída**", clique em "**Adicionar regra**".

9. Adicione uma regra para permitir tráfego para o **RDS**:

    - Tipo: personalizado
    - Porta: 3306 
    - Tipo de destino: selecione o **grupo de segurança do RDS**

10. Adicione uma regra para permitir tráfego para o **EFS**:

    - Tipo: personalizado
    - Porta: 2049 
    - Tipo de destino: selecione o **grupo de segurança do EFS**

11. Adicione uma regra para o **HTTPS**:

    - Tipo: HTTPS
    - Porta: 443 
    - Tipo de destino: 0.0.0.0/0 (para atualizações de pacotes ou chamadas externas)

12. Clique em "**Salvar regras**".

#### 3.5 Grupo de Segurança do Elastic File System (EFS)

1. Selecione o grupo de segurança do EFS, clique em "**Ações**" e "**Editar regras de saída**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**".

3. Adicione uma regra para o **NFS**:

    - Tipo: NFS
    - Porta: 2049
    - Tipo de origem: selecione o **grupo de segurança das instâncias EC2**

4. Clique em "**Salvar regras**".

5. Verifique as "**Regras de saída**":

    - Como o EFS não inicia conexões, não é necessário configurar regras de saída

#### 3.6 Grupo de Segurança do Relational Database Service (RDS)

1. Selecione o grupo de segurança do RDS, clique em "**Ações**" e "**Editar regras de saída**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**".

3. Adicione uma regra para o **MySQL/Aurora**:

    - Tipo: MySQL/Aurora
    - Porta: 3306
    - Tipo de origem: selecione o **grupo de segurança das instâncias EC2**

4. Clique em "**Salvar regras**".

5. Verifique as "**Regras de saída**":

    - Como o RDS não inicia conexões, não é necessário configurar regras de saída

## 4. Configuração do Elastic File System (EFS)

Iremos configurar um sistema de arquivos elástico para que as instâncias que hospedam o WordPress possam compartilhar arquivos mesmo em diferentes zonas de disponibilidade.

#### 4.1 Configurações Gerais

1. Na barra de pesquisa do console AWS, procure por "**EFS**".

2. Na página inicial do serviço, clique em "**Criar sistema de arquivos**" e "**Personalizar**".

3. Dê um nome ao sistema de arquivos.

4. Em "**Tipo do sistema de arquivos**", selecione "**Regional**".

5. Mantenha as **configurações gerais** padrão:

    - Backup automático: **Habilitado**
    - Gerenciamento de ciclo de vida: 
        - Transição para Infrequent Access: **30 dias desde o último acesso**
        - Transição para Archive: **90 dias desde o último acesso**
        - Transição para o Padrão: **Nenhum**
    - Criptografia: **Habilitado**

6. Mantenha as **configurações de performance** padrão:

    - Modo de taxa de transferência: "**Avançado**" e "**Elastic**"

7. Verifique as **configurações adicionais** e cerfique-se de que "**Uso geral**" está selecionado. 

8. Opcionalmente, adicione tags descritivas ao sistema de arquivos para melhorar a identificação dos recursos.

9. Clique em "**Próximo**".

#### 4.2 Configurações de Rede

1. Em "**Rede**", selecione a VPC criada para o projeto. 

2. Em "**Destinos de montagem**", adicionaremos dois destinos de montagem, um para cada zona de disponibilidade: 

    AZ 1:
    - Zona de disponibilidade: "**us-east-1a**"
    - ID da sub-rede: selecione a **sub-rede privada** disponível
    - Endereço de IP: mantenha o padrão ("**Automático**")
    - Grupos de segurança: selecione o **grupo de segurança do EFS**
   
    AZ 2:
    - Zona de disponibilidade: "**us-east-1b**"
    - ID da sub-rede: selecione a **sub-rede privada** disponível
    - Endereço de IP: mantenha o padrão ("**Automático**")
    - Grupos de segurança: selecione o **grupo de segurança do EFS**

3. Clique em "**Próximo**".

#### 4.3 Política do Sistema de Arquivos

Mantenha todas as opções como padrão e clique em "**Próximo**".

#### 4.4 Revisão das Configurações

Nessa etapa, verifique todas as configurações. Se tudo estiver conforme configurado nas etapas anteriores, clique em "**Criar**".

## 5. Configuração do Relational Database Service (RDS)

Iremos configurar o Amazon RDS para garantir que ambas as aplicações do WordPress tenham uma base de dados persistente e escalável, com alta disponibilidade entre diferentes zonas de disponibilidade. O RDS é um serviço gerenciado de banco de dados que facilita a configuração, operação e escalabilidade de vários tipos de bancos de dados, como MySQL, PostgreSQL, MariaDB, Oracle e SQL Server, com backups automáticos, failover e segurança integrados. Para esse projeto, iremos utilizar uma instância do **MySQL** no RDS.

#### 5.1 Configurações Gerais

1. Na barra de pesquisa do console AWS, procure por "**RDS**".

2. Na página inicial do serviço, clique em "**Criar banco de dados**". 

3. Selecione "**Criação padrão**".

4. Em "**Opções de mecanismo**", selecione o banco de dados "**MySQL**" e mantenha a versão do mecanismo padrão.

5. Em "**Modelos**", selecione "**Nível gratuito**".

6. Em "**Configurações**", dê um nome descritivo à instância do banco de dados.

7. Em "**Configurações de credenciais**", digite um nome de usuário para a instância do banco de dados. Esse será o ID do usuário principal do banco de dados.

8. Em "**Gerenciamento de credenciais**", selecione "**Configurações de credenciais**". Nessa opção, o RDS gera uma senha e a gerencia durante todo o ciclo de vida usando o **AWS Secrets Manager**.

9. Em "**COnfiguração da instância**", selecione "**db.t3.micro**".

10. Em "**Armazenamento**", mantenha as opções padrão.

#### 5.2 Configurações de Rede

1. Em "**Conectividade**", selecione "**Não se conectar a um recurso de computação do EC2**". Iremos configurar a conexão às instâncias EC2 manualmente mais tarde.

2. Em "**Nuvem privada virtual (VPC)**", selecione a VPC criada para o projeto.

3. Em "**Grupo de sub-redes de banco de dados**", selecione a opção *""Criar novo grupo de sub-redes do banco de dados**".

4. Em "**Acesso público**", selecione a opção "**Não**".

5. Em "**Grupo de segurança de VPC (firewall)**", selecione a opção "**Selecionar existente**", e, em "**Grupos de segurança da VPC existentes**", selecione o **grupo de segurança do RDS** criado anteriormente.

6. Em "**Zona de disponibilidade**", selecione a opção "**Sem preferência**".

#### 5.3 Configurações de Autenticação 

1. Em "**Autenticação de banco de dados**", selecione a opção "**Autenticação de senha**".

#### 5.4 Configurações Adicionais

1. Em "**Nome do banco de dados inicial**", dê um nome descritivo ao banco de dados.

> [!IMPORTANT]
> É recomendável especificar um nome de banco de dados ao criar o RDS. Caso contrário, o RDS criará apenas a instância do MySQL sem um banco de dados dentro dela, e você precisará criá-lo manualmente depois.

2. Mantenha as demais configurações (Backup, Criptografia, Logs, etc.) padrão.

3. Em "**Custos mensais estimados**", revise as informações e certifique-se de que o uso se enquadra no nível gratuito.

4. Se tudo estiver conforme configurado nas etapas anteriores, clique em "**Criar banco de dados**".

## 6. Configuração do Application Load Balancer

O serviço de **Elastic Load Balancing** distribui automaticamente o tráfego entre vários alvos, como instâncias EC2, contêineres e IPs, em múltiplas zonas de disponibilidade. Ele monitora a saúde dos alvos e encaminha requisições apenas para os que estão operacionais, ajustando sua capacidade conforme a demanda. A AWS oferece diferentes tipos de balanceadores de carga. Para esse projeto, utilizaremos o **Application Load Balancer (ALB)**, que opera na camada 7 (Aplicação) do modelo OSI, sendo o ideal para distribuir tráfego HTTP para as instâncias EC2 que hospedam o WordPress.

#### 6.1 Configurações Gerais

1. Na barra de pesquisa do console AWS, procure por "**Balanceadores de carga**".

2. Clique em "**Criar load balancer**".

3. Como **tipo de load balancer**, selecione "**Application Load Balancer**" e clique em "**Criar**".

4. Dê um nome descritivo ao load balancer.

5. Em "**Esquema**", selecione "**Voltado para a internet**".

6. Em "**Tipo de endereço IP do balanceador de carga**", mantenha padrão (**IPv4**).

#### 6.2 Configurações de Rede

1. Em "**Mapeamento de rede**", selecione a VPC criada para o projeto.

2. Em "**Mapeamentos**", selecione as duas zonas de disponibilidade (**us-east-1a** e **us-east-1b**) e selecione uma **sub-rede pública** em cada uma delas.

3. Em "**Grupos de segurança**", selecione o **grupo de segurança do ALB**.

4. Em "**Listeners e roteamento**", certifique-se de que o protocolo **HTTP** está selecionado (Porta **80**).

5. Em "**Ação padrão**", abaixo da barra de seleção do grupo de destino, clique em "**Criar grupo de destino**".

6. Crie um grupo de destino para as **instâncias EC2**:

    - Tipo de destino: **Instâncias**
    - Nome do grupo de destino: dê um nome descritivo
    - Protocolo e Porta: **HTTP:80**

7. Em "**VPC**", certifique-se de que a VPC criada para o projeto está selecionada. 

8. Mantenha as demais opções padrão e clique em "**Próximo**".

9. Em "**Registrar destinos**", pularemos essa etapa de registro das instâncias EC2 manualmente no grupo de destino. Quando o Auto Scaling Group (ASG) for criado e configurado para utilizar esse grupo de destino, as instâncias EC2 gerenciadas pelo ASG serão registradas automaticamente. 

10. Volte para a página de criação do ALB e, em "**Listeners e roteamento**", selecione o grupo de destino criado anteriormente.

11. Clique em "**Criar load balancer**".