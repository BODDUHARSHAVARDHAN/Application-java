#!/bin/bash
sudo -n tee /etc/systemd/system/java-app.service > /dev/null <<EOL
[Unit]
Description=Java Application Service
After=network.target

[Service]
ExecStart=/usr/bin/java -jar /opt/java-app/demo-0.0.1-SNAPSHOT.jar
User=harsha
Restart=always

[Install]
WantedBy=multi-user.target
EOL

sudo -n systemctl daemon-reload
sudo -n systemctl enable java-app.service
sudo -n systemctl start java-app.service
