#!/bin/bash

###############################################################################
# setup_rag.sh — Odoo Expert RAG Doc Setup Script
# Installs, processes, and launches the chatbot service under /opt/
#
# Usage:
#   sudo ./setup_rag.sh
###############################################################################

# ========== Configuration ==========
INSTALL_ROOT="/opt"
APP_NAME="rag-chatbot"
APP_USER="raguser"
REPO_URL="https://github.com/Salem4dev/odoo-expert-RAG-Doc.git"
PYTHON_BIN="python3.12"  # Change to "python3" if needed

APP_DIR="$INSTALL_ROOT/$APP_NAME"
VENV_DIR="$APP_DIR/venv"
RAW_DIR="$APP_DIR/rawdata"
DOCS_DIR="$APP_DIR/docs"
EMBED_DIR="$APP_DIR/db/embeddings"
SERVICE_NAME="$APP_NAME"
SERVICE_PORT="8501"
SERVICE_MODE="ui"

# ========== Create system user ==========
if ! id "$APP_USER" &>/dev/null; then
    echo "→ Creating system user: $APP_USER"
    sudo useradd -r -s /bin/false "$APP_USER"
fi

# ========== Prepare directories ==========
echo "→ Creating application directory: $APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo chown "$USER":"$USER" "$APP_DIR"
cd "$APP_DIR"

# ========== Clone repository ==========
if [ ! -d "$APP_DIR/.git" ]; then
    echo "→ Cloning repository into $APP_DIR"
    git clone "$REPO_URL" .
else
    echo "→ Repository already exists, pulling latest changes"
    git pull
fi

# ========== Setup Python virtualenv ==========
if [ ! -x "$VENV_DIR/bin/python" ]; then
    echo "→ Creating virtualenv using $PYTHON_BIN"
    $PYTHON_BIN -m venv "$VENV_DIR"
fi

echo "→ Activating virtualenv"
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

echo "→ Installing Python dependencies"
pip install --upgrade pip
pip install -r requirements.txt

# ========== Prepare data folders ==========
mkdir -p "$RAW_DIR" "$DOCS_DIR" "$EMBED_DIR"

# ========== Process raw documentation ==========
echo "→ Processing raw documentation"
$VENV_DIR/bin/python main.py process-raw --raw-dir "$RAW_DIR" --output-dir "$DOCS_DIR"

# ========== Generate embeddings ==========
echo "→ Generating embeddings"
$VENV_DIR/bin/python main.py process-docs --docs-dir "$DOCS_DIR" --output-dir "$EMBED_DIR"

# ========== Create systemd service ==========
echo "→ Creating systemd service: $SERVICE_NAME"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"

sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Odoo Expert RAG Chatbot Service
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
ExecStart=$VENV_DIR/bin/python main.py serve --mode $SERVICE_MODE --host 0.0.0.0 --port $SERVICE_PORT
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

echo "→ Reloading and starting service"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "✅ Setup complete. Service '$SERVICE_NAME' is running on port $SERVICE_PORT."
