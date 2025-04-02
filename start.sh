#!/bin/bash

# Start Stream Server Script - Nova Versão com NGINX + RTMP Module (sem MediaMTX)
# Inspirado na arquitetura do YouTube Live: usa nginx-rtmp como servidor

clear
LOG_FILE="status_transmissao_$(date +%Y%m%d_%H%M%S).log"
HTML_REPORT="relatorio_transmissao.html"
echo "Iniciando o servidor de transmissão WRTVBr (com NGINX-RTMP)..." | tee -a "$LOG_FILE"

# Verifica dependências
for cmd in docker docker-compose curl; do
  if ! command -v $cmd &> /dev/null; then
    echo "Erro: $cmd não está instalado." | tee -a "$LOG_FILE"
    exit 1
  fi
done

# Verifica arquivos obrigatórios
MISSING=false
for file in docker-compose.yml nginx.conf player/player.html; do
  if [ ! -e "$file" ]; then
    echo "Arquivo faltando: $file" | tee -a "$LOG_FILE"
    MISSING=true
  fi
done
if [ "$MISSING" = true ]; then
  echo "Corrija os arquivos ausentes antes de continuar." | tee -a "$LOG_FILE"
  exit 1
fi

# Remove containers antigos se existirem
docker rm -f nginx-rtmp &>/dev/null

# Sobe os containers
echo "Subindo container com NGINX-RTMP..." | tee -a "$LOG_FILE"
docker-compose up -d --force-recreate >> "$LOG_FILE" 2>&1
sleep 5

# Diagnóstico direto
echo "--- Containers em execução ---" | tee -a "$LOG_FILE"
docker ps | tee -a "$LOG_FILE"

NGINX_STATUS="falha"
RTMP_STATUS="falha"

if docker ps | grep -q nginx-rtmp; then
  NGINX_STATUS="ok"
else
  echo "LOG DO NGINX: " >> "$LOG_FILE"
  docker logs nginx-rtmp >> "$LOG_FILE" 2>&1
fi

RTMP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/stat)
if [ "$RTMP_RESPONSE" = "200" ]; then
  RTMP_STATUS="ok"
fi

IP="138.219.76.186"
echo "Acesse seu player ao vivo: http://$IP/player.html" | tee -a "$LOG_FILE"

# Relatório HTML
cat <<EOF > "$HTML_REPORT"
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8">
  <title>Status da Transmissão</title>
  <style>
    body { font-family: sans-serif; padding: 20px; }
    .ok { color: green; font-weight: bold; }
    .falha { color: red; font-weight: bold; }
  </style>
</head>
<body>
  <h1>Status da Transmissão</h1>
  <ul>
    <li>NGINX-RTMP: <span class="$NGINX_STATUS">$NGINX_STATUS</span></li>
    <li>RTMP: <span class="$RTMP_STATUS">$RTMP_STATUS</span></li>
  </ul>
  <p>Player: <a href="http://$IP/player.html">http://$IP/player.html</a></p>
  <p>Log salvo em: $LOG_FILE</p>
</body>
</html>
EOF

echo "Relatório gerado: $HTML_REPORT"
echo "Logs em tempo real: pressione Ctrl+C para sair"
docker logs -f nginx-rtmp &
wait
