#!/usr/bin/env bash

# Получаем имя текущего пользователя
echo "USER_NAME=$(whoami)"
USER_NAME=$(whoami)

# Получаем директорию, где лежит скрипт
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
echo "SCRIPT_DIR=$SCRIPT_DIR"

# Запрашиваем пароль для JupyterLab
echo "Set password for JupyterLab admin panel:"
read -s PASSWORD

# Устанавливаем зависимости
echo "Install gcc python3-dev"
sudo apt -y install gcc python3-dev

# Создаем виртуальное окружение
echo "Creating virtual environment..."
python3 -m venv --system-site-packages "${SCRIPT_DIR}/venv"


# Активируем виртуальное окружение
echo "Activate virtual environment..."
source "${SCRIPT_DIR}/venv/bin/activate"

# Устанавливаем JupyterLab
echo "Install jupyterlab..."
pip install jupyterlab

# Генерируем хэш для JupyterLab
JUPYTER_PASSWORD_HASH=$(python -c "from jupyter_server.auth import passwd; print(passwd('$PASSWORD'))")

# Создаем сервис автозапуска JupyterLab 8888
SERVICE_FILE="/etc/systemd/system/jupyterlab.service"
echo "Creating systemd service at $SERVICE_FILE..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=JupyterLab Autostart
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/env bash -c 'sleep 5 && source "${SCRIPT_DIR}/venv/bin/activate" && python3 -m jupyterlab --ip=0.0.0.0 --no-browser --NotebookApp.password='\''$JUPYTER_PASSWORD_HASH'\'
WorkingDirectory=${SCRIPT_DIR}
User=${USER_NAME}

[Install]
WantedBy=default.target
EOF

# Включаем и запускаем сервис
sudo systemctl stop jupyterlab.service
sudo systemctl disable jupyterlab.service
sudo systemctl daemon-reload
sudo systemctl enable jupyterlab.service
sudo systemctl start jupyterlab.service
