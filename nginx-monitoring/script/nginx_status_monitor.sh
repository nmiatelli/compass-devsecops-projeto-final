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