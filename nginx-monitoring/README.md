# Monitoramento Automatizado do nginx no Ubuntu 20.04 LTS

## Sobre o projeto

A prática consiste na instalação do WSL (Subsistema do Windows para Linux) no Windows e na criação de uma instância Ubuntu 20.04 LTS. Inclui também a configuração de um servidor nginx, o monitoramento do status do serviço por meio de um script personalizado e a automatização da execução deste script a cada 5 minutos. O script deve conter a data, hora, o nome do serviço, o status e uma mensagem personalizada de ONLINE ou OFFLINE. O objetivo é garantir a continuidade e a disponibilidade do serviço, registrando seu status em arquivos separados.

### Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Ativação e configuração do WSL](#2-ativação-e-configuração-do-wsl)
3. [Instalação e Configuração do Ubuntu 20.04 LTS](#3-instalação-e-configuração-do-ubuntu-2004-lts)
4. [Instalação e Configuração do nginx](#4-instalação-e-configuração-do-nginx)
5. [Criação do script de Monitoramento](#5-criação-do-script-de-monitoramento-do-status-do-nginx)
   - 5.1 [Configuração do Diretório de Logs](#51-configuração-do-diretório-de-logs)
   - 5.2 [Criação do Script](#52-criação-do-script)
6. [Automatização do Script](#6-automatização-do-script)
   - 6.1 [Validando a Automatização do Script](#61-validando-a-automatização-do-script)
7. [Referências](#7-referências)

## 1. Pré-requisitos

- Windows 10 versão 2004 e superior ou Windows 11
- Conhecimento básico do terminal Linux

## 2. Ativação e configuração do WSL

Clique com o botão direito do mouse sobre o PowerShell ou o Prompt de Comando do Windows e selecione **"Executar como administrador"**.

Depois, execute o comando:

```powershell
wsl --install
```

Após executado o comando e terminado a instalação do WSL, reinicie o computador.

## 3. Instalação e Configuração do Ubuntu 20.04 LTS

Abra o PowerShell como administrador e execute o comando:

```powershell
wsl --install -d Ubuntu-20.04
```

<details>
<summary>Instalação pela Microsoft Store</summary>
</br>Alternativamente, você pode abrir a Microsoft Store, buscar por "Ubuntu 20.04 LTS", clicar em adquirir e instalar a distribuição.
</details>

Terminado o processo de instalação do Ubuntu no WSL, você será solicitado a criar um nome de usuário e senha. Esta conta será o **usuário padrão e administrador da distribuição**, com permissões para executar comandos de super usuário (`sudo`).

## 4. Instalação e Configuração do nginx

Abra o terminal do Ubuntu e execute o seguinte comando para garantir a instalação do pacote correto e sua versão mais recente:

```bash
sudo apt update
```

Após isso, instale o nginx:

```bash
sudo apt install nginx
```

Inicie e verifique o status do nginx:

```bash
sudo systemctl start nginx
```

```bash
sudo systemctl status nginx
```

Caso o nginx esteja rodando corretamente, o comando retornará uma saída como esta:

![Status do nginx Ativo](imgs/nginx_status_ativo.jpeg)

Para verificar se o servidor está funcionando, abra o navegador e digite "https://localhost" na barra de endereços. 'Localhost' aponta para o IP do seu próprio computador, permitindo que você acesse o servidor localmente. Se tudo estiver certo, o servidor vai mostrar a página padrão do nginx:

![Página Padrão do nginx](imgs/nginx_via_localhost.jpeg)

## 5. Criação do script de monitoramento do status do nginx

### 5.1 Configuração do Diretório de Logs

Antes de criar o script, criaremos o diretório onde serão armazenados os logs de monitoramento do nginx:

```bash
sudo mkdir /var/log/nginx_status
```

Altere a propriedade do diretório para seu usuário:

```bash
sudo chown seu_usuario:seu_usuario /var/log/nginx_status
```

Em seguida, ajuste as permissões:

```bash
sudo chmod 755 /var/log/nginx_status
```

Essa configuração garante que você tenha acesso total ao diretório, enquanto outros usuários podem apenas ler e executar os arquivos dentro dele.

### 5.2 Criação do Script

Armazenanaremos o script dentro do diretório `/usr/local/bin`. Esse diretório já está incluído no PATH por padrão, permitindo a execução do script de qualquer lugar, sem precisar especificar o caminho completo.

Para criar e editar o script, utilize um editor de texto. Utilizando o `nano`:

```bash
sudo nano /usr/local/bin/nginx_status_monitor.sh
```

Digite o script:

```bash
#!/bin/bash

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

Pressione `CTRL + O` e `ENTER` para salvar e `CTRL + X` para sair. Após isso, garanta permissão de execução ao script para que você possa rodá-lo:

```bash
sudo chmod +x /usr/local/bin/nginx_status_monitor.sh
```

Para verificar se está funcionando corretamente, execute o script manualmente:

```bash
nginx_status_monitor.sh
```

E verifique os arquivos de log correspondentes. Exemplo do arquivo de log `nginx_online.log` com os logs do serviço ativos:

![Entrada de Log Online Manual](imgs/manual_online_log_entry.jpeg)

## 6. Automatização do Script

Para automatizar a execução do script, usaremos o serviço **cron**. O cron é um serviço do sistema operacional responsável por agendar e executar tarefas automaticamente em intervalos definidos. Ele usa o arquivo **crontab** para armazenar as configurações das tarefas, que podem ser executadas em horários específicos. Para automatizar nosso script, execute o seguinte comando para abrir e editar o crontab:

```bash
crontab -e
```

Selecione um editor de texto. Adicione a seguinte linha ao arquivo:

```bash
*/5 * * * * /usr/local/bin/nginx_status_monitor.sh
```

Salve e saia do arquivo.

Os arquivos de configuração do cron possuem cinco campos para especificar tempo e data, seguidos pelo comando que será executado. Cada um desses cinco campos é separado por um espaço e não podem haver espaços dentro de cada campo. Eles são os seguintes:

- Minuto (0-59)
- Hora (0-23, onde 0 = meia-noite)
- Dia do mês (1-31)
- Mês (1-12)
- Dia da semana (0-6, onde 0 = domingo)

Um asterisco (\*) pode ser usado para indicar que todas as ocorrências (todas as horas, todos os dias da semana, todos os meses, etc.) de um período de tempo devem ser consideradas.

Sendo asssim, no nosso caso, a expressão \*/5 \* \* \* \* faz com que o script seja executado a cada 5 minutos, independentemente da hora, dia do mês, mês ou dia da semana.

### 6.1 Validando a automatização do script

Após salvar as configurações no crontab, inicia-se a execução do script a cada cinco minutos. Podemos checar a lista de tarefas agendadas no cron com o seguinte comando:

```bash
crontab -l
```

O comando deve retornar a tarefa configurada anteriormente como na imagem seguinte:

![Crontab -l Output](imgs/crontab-l.jpeg)

Exemplo das saídas no arquivo de log com o serviço online:

![Logs do Cron Online](imgs/online_log_cron_entries.jpeg)

Exemplo das saídas no arquivo de log com o serviço offline:

![Logs do Cron Offline](imgs/offline_log_cron_entries.jpeg)

## 7. Referências

- [Documentação do WSL](https://docs.microsoft.com/en-us/windows/wsl/)
- [Documentação do nginx](https://nginx.org/en/docs/)
