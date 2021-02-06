#!/bin/bash

ddapikey=${1}
solrport=8983
anglport=4200
FILE=Vagrantfile
wksp=workspace
ddenv=testing
ddservice=solr
# mkdir solrAPM
# cd solrAPM/


if test -f "$FILE"; then
    echo "${FILE} has been configured, exiting setup now."
    # exit 0
else
    echo "${FILE} will be created for the first time."
    vagrant init fscm/solr
    # Create shared dir between local & vagrant hosts
    mkdir ${wksp}
fi

# Add the following to line 27, where the forwarded port can be enabled
sed -i '' '27i\
\ \ config.vm.network "forwarded_port", guest: '${solrport}', host: '${solrport}'\
\ \ config.vm.network "forwarded_port", guest: '${anglport}', host: '${anglport}'\
' ${FILE}

# Add the following to line 49, to share a 
sed -i '' '49i\
\ \ config.vm.synced_folder "'${wksp}'", "/home/vagrant/'${wksp}'"\
' ${FILE}

sed -i '' '73i\
\ \ config.vm.provision "shell", inline: <<-SHELL\
\ \ \ \ sudo apt-get update\
\ \ \ \ DD_AGENT_MAJOR_VERSION=7 DD_API_KEY='${ddapikey}' DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"\
\ \ \ \ wget -O /home/vagrant/'${wksp}'/dd-java-agent.jar https://dtdg.co/latest-java-tracer\
\ \ \ \ sudo echo "ENABLE_REMOTE_JMX_OPTS=\"true\"" >> /srv/solr/bin/solr.in.sh\
\ \ \ \ sudo echo "RMI_PORT=18983" >> /srv/solr/bin/solr.in.sh\
\ \ \ \ sudo echo "SOLR_OPTS="$SOLR_OPTS -javaagent:/home/vagrant/'${wksp}'/dd-java-agent.jar" >> /srv/solr/bin/solr.in.sh\
\ \ \ \ sudo echo "SOLR_OPTS="$SOLR_OPTS -Ddd.env='${ddenv}'" >> /srv/solr/bin/solr.in.sh\
\ \ \ \ sudo echo "SOLR_OPTS="$SOLR_OPTS -Ddd.service='${ddservice}'" >> /srv/solr/bin/solr.in.sh\
\ \ \ \ sudo sed -i \'\''s/^# env: <environment name>$/env: '${ddenv}'/g\'\'' /etc/datadog-agent/datadog.yaml\
\ \ \ \ sudo sed -i \'\''s/^# apm_config:$/apm_config:/g\'\'' /etc/datadog-agent/datadog.yaml\
\ \ \ \ sudo sed -i \'\''s/^  # enabled: true$/    enabled: true/g\'\'' /etc/datadog-agent/datadog.yaml\
\ \ \ \ sudo sed -i \'\''s/^  # env: none$/    env: '${ddenv}'/g\'\'' /etc/datadog-agent/datadog.yaml\
\ \ \ \ cd /home/vagrant/'${wksp}'/\
\ \ \ \ curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -\
\ \ \ \ sudo apt-get install -y nodejs\
\ \ \ \ sudo npm install -g yarn@1.13.0\
\ \ \ \ sudo npm install -g @angular/cli@7.3.8\
\ \ \ \ git clone https://github.com/leobouts/yelp.ene.git\
\ \ \ \ cd yelp.ene\
\ \ \ \ npm install\
\ \ SHELL\
' ${FILE}

vagrant up
vagrant ssh
