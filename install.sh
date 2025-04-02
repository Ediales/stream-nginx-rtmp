#!/bin/bash

# Script automático de instalação WRTVBr NGINX RTMP
echo "🔧 Clonando repositório WRTVBr..."
git clone https://github.com/Ediales/stream-nginx-rtmp.git
cd stream-nginx-rtmp || exit 1

echo "🚀 Iniciando start.sh..."
chmod +x start.sh
./start.sh
