#!/bin/bash
# Install cronie on an AWS EC2 instance, tested on Amazon Linux 2023

sudo yum install cronie -y
sudo systemctl enable crond --now
# crontab -e
# 0 0,12 * * * cd /home/ec2-user/webploy && script/run-certbot.sh renew >> /home/ec2-user/certbot-renew.log 2>&1
# 
