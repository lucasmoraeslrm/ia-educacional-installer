#!/bin/bash
# Script de instalação completa do sistema IA Educacional com RAG na VPS Ubuntu 22.04
# Domínio: education.ovortex.tech

set -e

# === 1. Atualização do sistema ===
echo "[1/7] Atualizando sistema..."
apt update && apt upgrade -y

# === 2. Instalar dependências do sistema ===
echo "[2/7] Instalando dependências do sistema..."
apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git

# === 3. Criar diretório do projeto ===
echo "[3/7] Configurando diretório do projeto em /opt/ia_educacional..."
mkdir -p /opt/ia_educacional/documents
cd /opt/ia_educacional

# === 4. Criar ambiente Python e instalar dependências ===
echo "[4/7] Instalando ambiente Python e dependências..."
python3 -m venv venv
source venv/bin/activate

# Criar requirements.txt
cat <<EOF > requirements.txt
fastapi
uvicorn
PyPDF2
python-docx
beautifulsoup4
ebooklib
sentence-transformers
faiss-cpu
transformers
torch
EOF

pip install --upgrade pip
pip install -r requirements.txt

# === 5. Criar arquivo de serviço systemd ===
echo "[5/7] Criando serviço systemd..."
cat <<EOF > /etc/systemd/system/ia_educacional.service
[Unit]
Description=IA Educacional - RAG com FastAPI
After=network.target

[Service]
User=root
WorkingDirectory=/opt/ia_educacional
ExecStart=/opt/ia_educacional/venv/bin/uvicorn index:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === 6. Configurar NGINX ===
echo "[6/7] Configurando NGINX..."
cat <<EOF > /etc/nginx/sites-available/education
server {
    listen 80;
    server_name education.ovortex.tech;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

ln -s /etc/nginx/sites-available/education /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# === 7. Ativar domínio com HTTPS ===
echo "[7/7] Gerando certificado SSL..."
certbot --nginx -d education.ovortex.tech

# Ativar serviço IA Educacional
systemctl daemon-reexec
systemctl enable ia_educacional
systemctl start ia_educacional

# Fim
clear
echo "✅ Deploy concluído com sucesso! Acesse: https://education.ovortex.tech"
echo "Suba agora o arquivo index.py para /opt/ia_educacional/ via SFTP ou SCP."
echo "Ou copie diretamente e reinicie o serviço: systemctl restart ia_educacional"
