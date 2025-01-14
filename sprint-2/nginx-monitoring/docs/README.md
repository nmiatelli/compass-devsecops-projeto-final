[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# Monitoramento Automatizado do nginx no Ubuntu 

## Sobre o projeto

Este projeto consiste na criação de uma instância Amazon EC2 com Ubuntu Server 24.04 LTS para configurar um servidor nginx, monitorar o status do serviço por meio de um script personalizado e automatizar sua execução a cada 5 minutos. O script deve registrar a data, hora, nome do serviço, status e uma mensagem personalizada de ONLINE ou OFFLINE, o que possibilita monitorar a continuidade e a disponibilidade do serviço.

### Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Configuração do Ambiente Virtual (VPC)](#2-configuração-do-ambiente-virtual-vpc)
    - 2.1 [Configuração dos Recursos](#21-configuração-dos-recursos)
    - 2.2 [Criação da VPC](#22-criação-da-vpc)
3. [Configuração e Criação da Instância EC2](#3-configuração-e-criação-da-instância-ec2)
    - 3.1 [Configuração do Grupo de Segurança](#31-configuração-do-grupo-de-segurança)
    - 3.2 [Criação da Instância](#32-criação-da-instância)
    - 3.3 [Alocação do IP Elástico](#33-alocação-do-ip-elástico)
4. [Conectando à Instância](#4-conectando-à-instância)
    - 4.1 [Configuração da Chave SSH ](#41-configuração-da-chave-ssh)
    - 4.2 [Conexão via SSH](#42-conexão-via-ssh)
5. [Instalação e Configuração do nginx](#5-instalação-e-configuração-do-nginx)
6. [Criação do Script de Monitoramento](#6-criação-do-script-de-monitoramento-do-status-do-nginx)
   - 6.1 [Configuração do Diretório de Logs](#61-configuração-do-diretório-de-logs)
   - 6.2 [Criação do Script](#62-criação-do-script)
7. [Automatização do Script](#7-automatização-do-script)
   - 7.1 [Validando a Automatização do Script](#71-validando-a-automatização-do-script)
8. [Referências](#8-referências)

## 1. Pré-requisitos

- Uma conta ativa na AWS
- Conhecimento básico do terminal Linux
- Conhecimento básico do console AWS

## 2. Configuração do Ambiente Virtual (VPC)

Antes de criarmos nossa instância EC2, precisamos configurar o ambiente de rede onde ela será executada. Criaremos uma VPC (Virtual Private Cloud) dedicada ao projeto.

> [!NOTE]
> A AWS oferece duas opções para criação de VPC: manual e automática. Na criação manual,  você configura a VPC, sub-redes, roteadores, gateways e outras opções de rede de forma  personalizada. Já na opção automática, o **VPC wizard** cria a VPC com sub-redes públicas e  privadas, já anexa um gateway de internet, configura as tabelas de rotas e inclui um gateway NAT, caso seja necessário. Utilizaremos a criação automática com o VPC wizard. 

### 2.1 Configuração dos Recursos
 
1. No console AWS, acesse o serviço VPC e clique em "**Criar VPC**".

2. Em "**Geração automática de etiqueta de nome**", deixe marcado para gerar os nomes automaticamente.

3. No campo de entrada, digite a etiqueta que deseja utilizar como prefixo para o nome dos recursos que serão criados.

4. Configure os recursos: 

    - CIDR da VPC: 10.0.0.0/24 (fornece 256 endereços IP, suficiente para o projeto)
    - Número de zonas de disponibilidade (AZs): 1 
    - Número de sub-redes públicas: 1 
    - Número de sub-redes privadas: 0 
    - Gateway NAT: Nenhuma
    - VPC endpoints: Nenhuma 

5. Opcionalmente, adicione tags descritivas à VPC. Isso ajuda a identificar facilmente os recursos associados ao projeto.

## 2.2 Criação da VPC 

1. Clique em "**Criar VPC**" e aguarde a criação dos recursos.

2. O wizard criará automaticamente:

    - Uma VPC com DNS hostnames habilitado
    - Uma sub-rede pública na AZ selecionada
    - Um gateway de internet anexado à VPC
    - Uma tabela de rota configurada com rota para o gateway de internet
    - Um grupo de segurança padrão

#### Preview do VPC Workflow

![VPC Workflow](../imgs/nginx-vpc-workflow.png)

## 3. Configuração e Criação da Instância EC2

Criaremos uma instância EC2 utilizando uma AMI do Ubuntu Server 24.04 LTS e iremos configurar um IP elástico para garantir um endereço consistente ao servidor nginx na instância. Além disso, iremos configurar regras específicas de entrada e saída no grupo de segurança da instância. A porta SSH (22) será limitada apenas ao seu IP para garantir acesso à instância de maneira segura e a porta HTTP (80) será aberta para qualquer IP (0.0.0.0/0) para que o servidor nginx seja acessível publicamente. Por fim, manteremos o tráfego de saída liberado para permitir que o servidor faça download de atualizações e pacotes necessários durante a instalação e operação do nginx.

### 3.1 Configuração do Grupo de Segurança 

1. Na aba de serviços, clique em "**EC2**".

2. No painel EC2, na seção "**Rede e Segurança**", clique em "**Grupos de segurança**".

3. Localize o grupo de segurança criado pela sua VPC (procure pelo grupo de segurança associado ao ID da sua VPC no painel de informações), e clique nele para editar.

4. Clique em editar as regras de entrada (Inbound rules).

5. Adicione uma regra para o **SSH**:

    - Tipo: SSH
    - Porta: 22
    - Tipo de origem: seu endereço de IP (use "**Meu IP**" para adicionar automaticamente)

6. Adicione uma regra para o "**HTTP**":

    - Tipo: HTTP
    - Porta: 80
    - Tipo de origem: Qualquer local-ipv4 (0.0.0.0/0)

7. Verifique as regras de saída (Outbound rules):

    - Mantenha a regra padrão que permite todo tráfego (0.0.0.0/0)

### 3.2 Criação da Instância

1. Na página principal do EC2, clique em "**Executar instância**".

2. Configurações gerais da instância:

    - Crie tags descritivas associadas ao projeto para facilitar o gerenciamento da instância no futuro.

    - Selecione a AMI do **Ubuntu Server 24.04 LTS**.

    - No **tipo de instância**, selecione a **t2.micro**. Para o caso de utilização do projeto, os recursos da t2.micro serão suficientes. Além disto, ela está inclusa no nível gratuito da AWS.

    - Crie um par de chaves ou selecione um par de chaves já existente. Elas serão necessárias para acessar a instância via SSH.

3. Configurações de rede da instância:

    - Em "**VPC**", selecione a VPC criada anteriormente para o projeto.

    - Em "**sub-rede**", selecione a sub-rede criada com a VPC.

    - Habilite a **atribuição de IP público automaticamente**.

    - Em "**Grupos de segurança comuns**", selecione o grupo de segurança criado com a VPC.

4. Mantenha as configurações de armazenamento padrões.

2. Revise as configurações. Caso esteja tudo correto, clique em "**Executar instância**".

### 3.3 Alocação do IP Elástico

1. No painel EC2, na seção "**Rede e Segurança**", navegue até "**IPs elásticos**".

2. Clique em "**Alocar endreço de IP elástico**".

3. Utilize o conjunto de endereços IPv4 da Amazon.

4. Se desejar, adicione tags descritivas associadas ao projeto.

5. Após criado, selecione o IP, clique em "**Ações**" e "**Associar endereço de IP elástico**".

6. Selecione a instância do servidor.

7. Clique em "**Associar**".

## 4. Conectando à Instância

Primeiro, iremos ajustar as permissões da chave privada. Em seguida, iremos usar essa chave para estabelecer uma conexão segura via SSH com a instância.

### 4.1 Configuração da Chave SSH 

1. Use o seguinte comando para definir as permissões do seu arquivo de chave privada para que somente você possa lê-lo:

   ```bash
   chmod 400 ~/caminho/da/chave.pem
   ```

> [!IMPORTANT]
> Se você não definir essas permissões, não será possível se conectar à sua instância usando esse par de chaves, pois, por questões de segurança, o cliente SSH rejeitará a chave.

### 4.2 Conexão via SSH

1. Abra o terminal no seu computador e use o comando `ssh` para se conectar à sua instancia. Você precisará da localização da chave privada (arquivo .pem), do nome de usuário e seu DNS público, como no exemplo abaixo:

```bash
ssh -i ~/caminho/da/chave.pem ubuntu@seu-dns-publico
```

2. Na primeira vez que se conectar, você verá um aviso de fingerprint. Aceite digitando "yes" para confirmar que está se conectando ao servidor correto e salvá-lo para futuras conexões seguras. Após a conexão, algumas informações sobre a distribuição Ubuntu serão exibidas, e o prompt do shell deve ser algo como:

```bash 
ubuntu@ip-10-0-0-xx:~$
```

## 5. Instalação e Configuração do nginx

1. Abra o terminal do Ubuntu e execute o seguinte comando para garantir a instalação do pacote correto e sua versão mais recente:

```bash
sudo apt update && sudo apt upgrade -y
```

2. Instale o nginx:

```bash
sudo apt install nginx -y
```

3. Verifique o status do nginx:

```bash
sudo systemctl status nginx
```

4. Caso o nginx esteja rodando corretamente, o comando retornará uma saída como essa:

![Status do nginx Ativo](../imgs/nginx_active_status.png)

5. Para garantir que o nginx inicie automaticamente após a reinicialização da instância, use o comando:

```bash
sudo systemctl enable nginx
```

6. Para verificar se o servidor está funcionando, abra o navegador e digite o IP elástico da instância na barra de endereços. Se tudo estiver certo, o servidor deve mostrar a página padrão do nginx:

![Página Padrão do nginx](../imgs/nginx_default_homepage.png)

## 6. Criação do Script de monitoramento do status do nginx

### 6.1 Configuração do Diretório de Logs

1. Antes de criar o script, criaremos o diretório onde serão armazenados os logs de monitoramento do nginx:

```bash
sudo mkdir /var/log/nginx_status
```

2. Altere a propriedade do diretório para seu usuário:

```bash
sudo chown ubuntu:ubuntu /var/log/nginx_status
```

3. Ajuste as permissões:

```bash
sudo chmod 755 /var/log/nginx_status
```

Essa configuração garante que você tenha acesso total ao diretório, enquanto outros usuários podem apenas ler e executar os arquivos dentro dele.

### 6.2 Criação do Script

Iremos armazenar o script dentro do diretório `/usr/local/bin`. Esse diretório já está incluído no PATH por padrão, permitindo a execução do script de qualquer lugar, sem precisar especificar o caminho completo.

1. Para criar e editar o script, utilize um editor de texto. Utilizando o `nano`:

```bash
sudo nano /usr/local/bin/nginx_status_monitor.sh
```

2. Digite o script:

```bash
#!/usr/bin/env bash

# obtém a data e hora atuais
data_hora=$(date "+%d-%m-%Y %H:%M:%S")

# nome do serviço
servico="nginx"

# status do serviço
status=$(systemctl is-active $servico)

# caminhos para os arquivos de log
log_online="/var/log/nginx_status/nginx_online.log"
log_offline="/var/log/nginx_status/nginx_offline.log"

# verifica o status do serviço nginx e escreve nos arquivos de log
if [ "$status" = "active" ]; then
    echo "Data e Hora: $data_hora | Serviço: $servico | Status: $status | O serviço $servico está ONLINE." >> "$log_online"
else
    echo "Data e Hora: $data_hora | Serviço: $servico | Status: $status | O serviço $servico está OFFLINE" >> "$log_offline"
fi
```

3. Pressione `CTRL + O` e `ENTER` para salvar e `CTRL + X` para sair. Após isso, garanta permissão de execução ao script para que você possa rodá-lo:

```bash
sudo chmod +x /usr/local/bin/nginx_status_monitor.sh
```

4. Para verificar se está funcionando corretamente, execute o script manualmente:

```bash
nginx_status_monitor.sh
```

5. Em seguida, verifique os arquivos de log correspondentes. Exemplo do arquivo de log `nginx_online.log` com os logs do serviço ativos:

![Entrada de Log Online Manual](../imgs/manual_online_log_entry.png)

## 7. Automatização do Script

Para automatizar a execução do script, utilizaremos o serviço **cron**. O cron é um serviço do sistema operacional responsável por agendar e executar tarefas automaticamente em intervalos definidos. Ele usa o arquivo **crontab** para armazenar as configurações das tarefas, que podem ser executadas em horários específicos. 

1. Para automatizar nosso script, execute o seguinte comando para abrir e editar o crontab:

```bash
crontab -e
```

2. Selecione um editor de texto. Adicione a seguinte linha ao arquivo:

```bash
*/5 * * * * /usr/local/bin/nginx_status_monitor.sh
```

3. Salve e saia do arquivo.

Os arquivos de configuração do cron possuem cinco campos para especificar tempo e data, seguidos pelo comando que será executado. Cada um desses cinco campos é separado por um espaço e não podem haver espaços dentro de cada campo. Eles são os seguintes:

- Minuto (0-59)
- Hora (0-23, onde 0 = meia-noite)
- Dia do mês (1-31)
- Mês (1-12)
- Dia da semana (0-6, onde 0 = domingo)

Um asterisco (\*) pode ser usado para indicar que todas as ocorrências (todas as horas, todos os dias da semana, todos os meses, etc.) de um período de tempo devem ser consideradas.

Sendo assim, no nosso caso, a expressão \*/5 \* \* \* \* faz com que o script seja executado a cada 5 minutos, independentemente da hora, dia do mês, mês ou dia da semana.

### 7.1 Validando a automatização do script

Após salvar as configurações no crontab, a execução do script será iniciada automaticamente a cada cinco minutos. 

1. Podemos checar a lista de tarefas agendadas no cron com o seguinte comando:

    ```bash
    crontab -l
    ```

    1.1 O comando deve retornar a tarefa configurada anteriormente como na imagem seguinte:

    ![Crontab -l Output](../imgs/crontab-l.png)

Exemplo das saídas no arquivo de log com o serviço online:

![Logs do Cron Online](../imgs/nginx_online_log_entry.png)

Exemplo das saídas no arquivo de log com o serviço offline:

![Logs do Cron Offline](../imgs/nginx_offline_log_entry.png)

## 8. Referências

- [Documentação da Amazon Virtual Private Cloud (VPC)](https://docs.aws.amazon.com/pt_br/vpc/?icmpid=docs_homepage_featuredsvcs)
- [Documentação do Amazon Elastic Compute Cloud (Amazon EC2)](https://docs.aws.amazon.com/pt_br/ec2/?icmpid=docs_homepage_featuredsvcs)
- [Documentação do nginx](https://nginx.org/en/docs/)
- [Guia de Configuração e Uso de Cron Jobs](https://www.pantz.org/software/cron/croninfo)
