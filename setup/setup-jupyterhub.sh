#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

CLASSNAME=csx46
DOMAIN_NAME=mydomain.com
INSTRUCTOR_USERNAME=ramseyst
EMAIL_ADDRESS="stephen.ramsey@oregonstate.edu"

sudo apt-get update

echo "installing basic packages needed for system administration"
sudo apt-get install -y emacs
sudo apt-get install -y lynx
sudo apt-get install -y mlocate
sudo updatedb

echo "installing python3"
sudo apt-get install -y python3-pip

echo "installing node.js"
sudo curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y npm nodejs

echo "installing configurable-http-proxy"
sudo npm install -g configurable-http-proxy

echo "setting up virtualenv"
sudo -H pip3 install virtualenv
virtualenv ${CLASSNAME}
${CLASSNAME}/bin/pip3 install jupyterhub
${CLASSNAME}/bin/pip3 install notebook
${CLASSNAME}/bin/pip3 install bash_kernel
export JUPYTER_DATA_DIR=${HOME}/${CLASSNAME}/share/jupyter
${CLASSNAME}/bin/python3 -m bash_kernel.install
git clone https://github.com/letsencrypt/letsencrypt
echo "About to run letsencrypt; select (1) to spin up a temporary webserver; enter the hostname when prompted for the 
domain name"
./letsencrypt/letsencrypt-auto certonly --debug --email ${EMAIL_ADDRESS} --domains ${CLASSNAME}.${DOMAIN_NAME} --standalone 

echo "creating JupyterHub config file"
${CLASSNAME}/bin/jupyterhub --generate-config
cp jupyterhub_config.py jupyterhub_config.py.ORIG
sed -i "s|#c.JupyterHub.ssl_key = ''|c.JupyterHub.ssl_key = '/etc/letsencrypt/live/${CLASSNAME}.${DOMAIN_NAME}/privkey.pem'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.ssl_cert = ''|c.JupyterHub.ssl_cert = '/etc/letsencrypt/live/${CLASSNAME}.${DOMAIN_NAME}/fullchain.pem'|g" jupyterhub_config.py
sudo mkdir -p /etc/jupyterhub
sed -i "s|#c.JupyterHub.cookie_secret_file = 'jupyterhub_cookie_secret'|c.JupyterHub.cookie_secret_file = '/srv/jupyterhub/jupyterhub_cookie_secret'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.admin_users = set()|c.JupyterHub.admin_users = {'${INSTRUCTOR_USERNAME}'}|g" jupyterhub_config.py
sed -i "s|#c.Authenticator.admin_users = set()|c.Authenticator.admin_users = {'${INSTRUCTOR_USERNAME}'}|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.bind_url = 'http://:8000'|c.JupyterHub.bind_url = 'http://0.0.0.0:8000'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.hub_bind_url = ''|c.JupyterHub.hub_bind_url = 'http://127.0.0.1:8081'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.cleanup_servers = True|c.JupyterHub.cleanup_servers = False|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.pid_file = ''|c.JupyterHub.pid_file = '/srv/jupyterhub/jupyterhub.pid'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.db_url = 'sqlite:////jupyterhub.sqlite'|c.JupyterHub.db_url = 'sqlite:///srv/jupyterhub/jupyterhub.sqlite'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.spawner_class = 'jupyterhub.spawner.LocalProcessSpawner'|c.JupyterHub.spawner_class = 'sudospawner.SudoSpawner'|g" jupyterhub_config.py
echo "c.ConfigurableHTTPProxy.pid_file = '/srv/jupyterhub/jupyterhub-proxy.pid'" >> jupyterhub_config.py
echo "c.PAMAuthenticator.open_sessions = False" >> jupyterhub_config.py
echo "c.Spawner.cmd = '${HOME}/${CLASSNAME}/bin/sudospawner'" >> jupyterhub_config.py
echo "c.SudoSpawner.sudospawner_path = '${HOME}/${CLASSNAME}/bin/sudospawner'" >> jupyterhub_config.py
sudo cp jupyterhub_config.py /etc/jupyterhub

echo "setting up SSL certificates"
sudo chmod 755 /etc/letsencrypt/live
sudo chmod 755 /etc/letsencrypt/archive
sudo chmod 644 /etc/letsencrypt/archive/${CLASSNAME}.${DOMAIN_NAME}/privkey1.pem

echo "creating Linux accounts that are needed"
sudo adduser -c "jupyterhub daemon" jupyterhub
sudo adduser -c "JupyterHub Main Administrator" ${INSTRUCTOR_USERNAME}

echo "creating directories and logfile needed by JupyterHub"
sudo mkdir -p /srv/jupyterhub
sudo chown jupyterhub.jupyterhub /srv/jupyterhub
sudo mkdir -p /var/log
sudo touch /var/log/jupyterhub.log
sudo chown jupyterhub.jupyterhub /var/log/jupyterhub.log

echo "creating run-jupyterhub.sh script"
cat <<EOT >run-jupyterhub.sh
#!/usr/bin/env bash
nohup sudo su - jupyterhub -c "exec ${HOME}/${CLASSNAME}/bin/jupyterhub -f /etc/jupyterhub/jupyterhub_config.py >/var/log/jupyterhub.log 2>&1" > /tmp/nohup.out 2>&1
EOT
chmod a+x run-jupyterhub.sh

echo "configuring jupyterhub to use sudospawner"
${CLASSNAME}/bin/pip3 install sudospawner
sudo groupadd jupyterhubusers
sudo usermod -a -G jupyterhubusers ${INSTRUCTOR_USERNAME}
sudo usermod -a -G shadow jupyterhub
cat <<EOT >>sudoers-jupyterhub
Cmnd_Alias JUPYTER_CMD = ${HOME}/${CLASSNAME}/bin/sudospawner
jupyterhub ALL=(%jupyterhubusers) NOPASSWD:JUPYTER_CMD
EOT
sudo mv sudoers-jupyterhub /etc/sudoers.d/jupyterhub
sudo chown root.root /etc/sudoers.d/jupyterhub
sudo chmod 444 /etc/sudoers.d/jupyterhub

echo "installing and configuring nginx"
sudo apt-get install -y nginx
cp /etc/nginx/nginx.conf nginx.conf
cat <<EOF >> nginx.conf
stream {
  server {
      listen     443;
      proxy_pass 0.0.0.0:8000;
  }
}
EOF
sudo mv nginx.conf /etc/nginx/nginx.conf
cat <<EOF > sites-enabled-default
server {
	listen 80 default_server;
	server_name _;
	return 301 https://$host$request_uri;
}
EOF
sudo mv sites-enabled-default /etc/nginx/sites-enabled/default
sudo service nginx stop

echo "installing R"
sudo apt install apt-transport-https software-properties-common
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y r-base
mkdir -p ${HOME}/R/x86_64-pc-linux-gnu-library/3.6
Rscript -e "install.packages('IRkernel', lib='${HOME}/R/x86_64-pc-linux-gnu-library/3.6')"
source ${HOME}/${CLASSNAME}/bin/activate
Rscript -e "IRkernel::installspec(prefix='${HOME}/${CLASSNAME}')"
deactivate
exit
sudo sed -i "s|R_LIBS_SITE=${R_LIBS_SITE-'\''/usr/local/lib/R/site-library:/usr/lib/R/site-library:/usr/lib/R/library'\''}|R_LIBS_SITE=${R_LIBS_SITE-'\''${HOME}/R/x86_64-pc-linux-gnu-library/3.6:/usr/local/lib/R/site-library:/usr/lib/R/site-library:/usr/lib/R/library'\''}|g" /etc/R/Renviron
echo "installing Ubuntu packages needed by Tidyverse"
sudo apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev

cat <<EOF > ${HOME}/${CLASSNAME}/bin/start-python.sh
#!/bin/bash
exec env PYTHONPATH=\${HOME}/.local/lib/python3.6/site-packages ${HOME}/${CLASSNAME}/bin/python3 $@
EOF
chmod a+x ${HOME}/${CLASSNAME}/bin/start-python.sh
sed -i "0,/python/ s|python|${HOME}/${CLASSNAME}/bin/start-python.sh|" ${HOME}/${CLASSNAME}/share/jupyter/kernels/python3/kernel.json
echo "installing texlive"
sudo apt-get install -y texlive

echo "installing R packages for the class"
Rscript -e 'install.packages(c("tidyverse", "igraph", "corpcor", "gdata", "lattice", "lpSolve", "plyr", "zoo"))'

echo "installing python packages for the class"
${CLASSNAME}/bin/pip3 install numpy scipy scikit-learn pandas matplotlib bintrees graphviz python-igraph networkx pympler statsmodels

echo "graphviz"
sudo apt-get install -y graphviz libgraphviz-dev
${CLASSNAME}/bin/pip3 install graphviz pydot pygraphviz

echo "setting up Jupyter notebook templates directory"
sudo mkdir /templates
sudo chown ubuntu.ubuntu /templates
sudo su - ${INSTRUCTOR_USERNAME} -c "ln -s /templates templates"
sudo chown ubuntu.ubuntu /home/${INSTRUCTOR_USERNAME}/templates

