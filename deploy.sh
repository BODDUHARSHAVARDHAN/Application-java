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

# Deployment logic
NEW_JAR="${JAR_PATH}/demo-$1-SNAPSHOT.jar"

# Update symbolic links
echo "Deploying new version: ${NEW_JAR}"
sudo -n mv ${SYMLINK_LATEST} ${SYMLINK_PREVIOUS}  # Backup the current latest as previous
sudo -n ln -sf ${NEW_JAR} ${SYMLINK_LATEST}  # Set new jar as the latest

update_systemd_config ${SYMLINK_LATEST}

# Start or restart the service
sudo -n systemctl restart java-app.service
