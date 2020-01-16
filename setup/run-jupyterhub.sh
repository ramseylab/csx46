#!/usr/bin/env bash
nohup sudo su - jupyterhub -c "exec /home/ubuntu/csx46/bin/jupyterhub -f /etc/jupyterhub/jupyterhub_config.py >/var/log/jupyterhub.log 2>&1" > /tmp/nohup.out 2>&1


