#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup_rag.sh
#
# Bootstraps the odoo-expert-RAG-Doc environment:
#   1. Creates/activates a Python venv (optional)
#   2. Clones odoo-expert-RAG-Doc if missing
#   3. Installs Python requirements
#   4. Pulls raw Odoo docs for the chosen branch
#   5. Symlinks your add-on source folders into rawdata/addons
#   6. Processes docs & builds vector embeddings
#   7. [Optional] Creates & enables a systemd service
#
# Usage:
#   sudo /opt/odoo/setup_rag.sh [--no-venv] [--systemd] [--service-name NAME]
#                            [<addon_path1> <addon_path2> …]
#
# Flags:
#   --no-venv           skip virtualenv creation & activation
#   --systemd           write & enable a systemd unit as SERVICE_USER
#   --service-name NAME name of the systemd service (default: rag-doc)
#
# If you supply <addon_path> arguments, they override the DEFAULT_ADDON_DIRS.
###############################################################################

##### 1) DEFAULT CONFIGURATION (edit these as needed) #####

# Base installation directory
BASE_DIR="/opt/odoo"

# Odoo server directory (contains v17, v18, enterprise, etc.)
ODOO_SERVER_DIR="$BASE_DIR/odoo-server"

# Default branch of Odoo docs to index
DEFAULT_BRANCH="17.0"

# Default add-on source folders
DEFAULT_ADDON_DIRS=(
  "$ODOO_SERVER_DIR/odoo/addons"
  "$ODOO_SERVER_DIR/addons"
)

# Virtualenv path and Python executable
VENV_PATH="$BASE_DIR/odoo-venv/python3.12"
PYTHON="$VENV_PATH/bin/python"

# Service user & default service name
SERVICE_USER="odoo"
DEFAULT_SERVICE_NAME="rag-chatbot"

###############################################################################
# 2) PARSE FLAGS & ARGUMENTS
###############################################################################

USE_VENV=true
CREATE_SYSTEMD=true
SERVICE_NAME="$DEFAULT_SERVICE_NAME"
BRANCH="$DEFAULT_BRANCH"
ADDON_SRC_DIRS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-venv)
      USE_VENV=false; shift ;;
    --systemd)
      CREATE_SYSTEMD=true; shift ;;
    --service-name)
      SERVICE_NAME="$2"; shift 2 ;;
    --branch)
      BRANCH="$2"; shift 2 ;;
    --)
      shift; break ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1 ;;
    *)
      ADDON_SRC_DIRS+=("$1"); shift ;;
  esac
done

# Fallback to defaults if no add-on paths provided
if [ ${#ADDON_SRC_DIRS[@]} -eq 0 ]; then
  ADDON_SRC_DIRS=("${DEFAULT_ADDON_DIRS[@]}")
fi

echo "→ Configuration:"
echo "   BASE_DIR        = $BASE_DIR"
echo "   BRANCH          = $BRANCH"
echo "   USE_VENV        = $USE_VENV"
echo "   VENV_PATH       = $VENV_PATH"
echo "   PYTHON          = $PYTHON"
echo "   CREATE_SYSTEMD  = $CREATE_SYSTEMD"
echo "   SERVICE_NAME    = $SERVICE_NAME"
echo "   ADDON_SRC_DIRS  ="
for p in "${ADDON_SRC_DIRS[@]}"; do echo "     • $p"; done
echo

###############################################################################
# 3) SETUP VIRTUALENV (optional)
###############################################################################
if $USE_VENV; then
  if [ ! -x "$PYTHON" ]; then
    echo "→ Creating Python venv at $VENV_PATH"
    python3 -m venv "$(dirname "$VENV_PATH")"
  fi
  echo "→ Activating virtualenv"
  # shellcheck source=/dev/null
  source "$VENV_PATH/bin/activate"
fi

###############################################################################
# 4) CLONE & INSTALL odoo-expert-RAG-Doc
###############################################################################
RAG_DIR="$BASE_DIR/odoo-expert-RAG-Doc"
if [ ! -d "$RAG_DIR" ]; then
  echo "→ Cloning odoo-expert-RAG-Doc into $RAG_DIR"
  git clone https://github.com/Salem4dev/odoo-expert-RAG-Doc.git "$RAG_DIR"
fi
cd "$RAG_DIR"

echo "→ Installing Python dependencies"
pip install --upgrade pip
pip install -r requirements.txt

###############################################################################
# 5) PULL RAW ODOO DOCUMENTATION
###############################################################################
echo "→ Pulling Odoo docs for branch $BRANCH"
chmod +x pull_rawdata.sh
./pull_rawdata.sh --branch "$BRANCH"

###############################################################################
# 6) SYMLINK ADD-ON SOURCE INTO rawdata/addons
###############################################################################
RAW_ADDONS="$RAG_DIR/rawdata/addons"
echo "→ Preparing $RAW_ADDONS"
rm -rf "$RAW_ADDONS"
mkdir -p "$RAW_ADDONS"

for src in "${ADDON_SRC_DIRS[@]}"; do
  if [ -d "$src" ]; then
    echo "   • Symlinking modules from $src"
    for mod in "$src"/*; do
      [ -d "$mod" ] && ln -sf "$mod" "$RAW_ADDONS/$(basename "$mod")"
    done
  else
    echo "⚠️  Source folder not found: $src"
  fi
done

###############################################################################
# 7) PROCESS & BUILD EMBEDDINGS
###############################################################################
echo "→ Cleaning raw data"
python process-raw.py --input rawdata/ --output docs/

echo "→ Building embeddings"
python process-docs.py --input docs/ --output db/embeddings/

echo
echo "✅ Setup complete!"
echo "   To launch the UI service manually:"
if $USE_VENV; then
  echo "     source $VENV_PATH/activate && python serve.py --mode ui"
else
  echo "     python serve.py --mode ui"
fi
echo

###############################################################################
# 8) CREATE & ENABLE SYSTEMD SERVICE (optional)
###############################################################################
if $CREATE_SYSTEMD; then
  UNIT_PATH="/etc/systemd/system/$SERVICE_NAME.service"
  echo "→ Creating systemd unit at $UNIT_PATH"
  sudo tee "$UNIT_PATH" > /dev/null <<EOF
[Unit]
Description=Odoo Expert RAG-Doc Service
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$RAG_DIR
ExecStart=$([ "$USE_VENV" = true ] \
  && echo "$PYTHON $RAG_DIR/serve.py --mode api --host 0.0.0.0 --port 8501" \
  || echo "python3 $RAG_DIR/serve.py --mode api --host 0.0.0.0 --port 8501")
Restart=on-failure
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

  echo "→ Reloading systemd and enabling service"
  sudo systemctl daemon-reload
  sudo systemctl enable "$SERVICE_NAME"
  sudo systemctl start  "$SERVICE_NAME"

  echo "✅ Service '$SERVICE_NAME' is now running on port 8501."
fi
