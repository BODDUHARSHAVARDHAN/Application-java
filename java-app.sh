#!/bin/bash

# Variables
JAR_PATH="/opt/java-app"
SYMLINK_LATEST="${JAR_PATH}/demo-latest.jar"
SYMLINK_PREVIOUS="${JAR_PATH}/demo-previous.jar"
SERVICE_FILE="/etc/systemd/system/java-app.service"
TIMESTAMP=$(date +'%Y%m%d%H%M%S')  # Generate a unique timestamp

# Function to update systemd configuration
update_systemd_config() {
    local jar_file=$1
    echo "Updating systemd configuration to use $jar_file..."

    sudo -n tee ${SERVICE_FILE} > /dev/null <<EOL
[Unit]
Description=Java Application Service
After=network.target

[Service]
ExecStart=/usr/bin/java -jar $jar_file
User=harsha
SuccessExitStatus=143
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    sudo -n systemctl daemon-reload
    if [[ $? -ne 0 ]]; then
        echo "Failed to reload systemd daemon. Exiting."
        exit 1
    fi

    sudo -n systemctl enable java-app.service
    if [[ $? -ne 0 ]]; then
        echo "Failed to enable the java-app.service. Exiting."
        exit 1
    fi
}

# Function to deploy a new version with a timestamp
deploy_new_version() {
    local version=$1
    local new_jar="${JAR_PATH}/demo-${version}-${TIMESTAMP}.jar"

    if [ ! -f "$new_jar" ]; then
        echo "Error: JAR file $new_jar does not exist!"
        exit 1
    fi

    echo "Deploying new version: ${new_jar}"

    # Backup the current latest as previous
    if [ -L "$SYMLINK_LATEST" ]; then
        sudo -n mv ${SYMLINK_LATEST} ${SYMLINK_PREVIOUS}
        if [[ $? -ne 0 ]]; then
            echo "Failed to backup the previous JAR. Exiting."
            exit 1
        fi
    fi

    # Update the latest symlink to point to the new version
    sudo -n ln -sf ${new_jar} ${SYMLINK_LATEST}
    if [[ $? -ne 0 ]]; then
        echo "Failed to create symlink to the new JAR. Exiting."
        exit 1
    fi

    update_systemd_config ${SYMLINK_LATEST}
}

# Function to rollback to the previous version
rollback_version() {
    echo "Rolling back to previous version..."
    
    if [ ! -L "$SYMLINK_PREVIOUS" ]; then
        echo "Error: No previous version found for rollback!"
        exit 1
    fi

    # Switch latest to the previous version
    sudo -n ln -sf ${SYMLINK_PREVIOUS} ${SYMLINK_LATEST}
    if [[ $? -ne 0 ]]; then
        echo "Failed to switch to previous version. Exiting."
        exit 1
    fi

    update_systemd_config ${SYMLINK_LATEST}
}

# Main logic
if [ "$1" == "rollback" ]; then
    rollback_version
else
    deploy_new_version $1
fi

# Start or restart the service
sudo -n systemctl restart java-app.service
if [[ $? -ne 0 ]]; then
    echo "Failed to restart the service. Exiting."
    exit 1
fi

echo "Service restarted successfully."
