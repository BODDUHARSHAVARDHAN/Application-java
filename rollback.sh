#!/bin/bash

# Variables
JAR_PATH="/opt/java"
SYMLINK_LATEST="${JAR_PATH}/demo-latest.jar"
SYMLINK_PREVIOUS="${JAR_PATH}/demo-previous.jar"
SERVICE_FILE="/etc/systemd/system/java.service"

# Function to update systemd configuration
update_systemd_config() {
    local jar_file=$1
    echo "Updating systemd configuration to use $jar_file..."
    
    sudo -n tee ${SERVICE_FILE} > /dev/null <<EOL
[Unit]
Description=Java Application Service
After=network.target

[Service]
ExecStart=/usr/bin/java -jar ${jar_file}
User=harsha
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    sudo -n systemctl daemon-reload
    sudo -n systemctl enable java.service
}

# Rollback logic
echo "Rolling back to previous version..."
sudo -n ln -sf ${SYMLINK_PREVIOUS} ${SYMLINK_LATEST}
update_systemd_config ${SYMLINK_LATEST}

# Restart the service
sudo -n systemctl restart java.service
