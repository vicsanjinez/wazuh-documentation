#!/bin/bash

# Program to install Wazuh manager along Open Distro for Elasticsearch
# Copyright (C) 2015-2021, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

## Check if system is based on yum or apt-get
char="."
debug='> /dev/null 2>&1'
if [ -n "$(command -v yum)" ]; then
    sys_type="yum"
elif [ -n "$(command -v zypper)" ]; then
    sys_type="zypper"     
elif [ -n "$(command -v apt-get)" ]; then
    sys_type="apt-get"   
fi

logger() {

    echo $1
    
}

checkArch() {
    arch=$(uname -m)

    if [ ${arch} != "x86_64" ]; then
        echo "Uncompatible system. This script must be run on a 64-bit system."
        exit 1;
    fi
}

startService() {

    if [ -n "$(ps -e | egrep ^\ *1\ .*systemd$)" ]; then
        eval "systemctl daemon-reload ${debug}"
        eval "systemctl enable $1.service ${debug}"
        eval "systemctl start $1.service ${debug}"
        if [  "$?" != 0  ]; then
            echo "${1^} could not be started."
            exit 1;
        else
            echo "${1^} started"
        fi  
    elif [ -n "$(ps -e | egrep ^\ *1\ .*init$)" ]; then
        eval "chkconfig $1 on ${debug}"
        eval "service $1 start ${debug}"
        eval "/etc/init.d/$1 start ${debug}"
        if [  "$?" != 0  ]; then
            echo "${1^} could not be started."
            exit 1;
        else
            echo "${1^} started"
        fi     
    elif [ -x /etc/rc.d/init.d/$1 ] ; then
        eval "/etc/rc.d/init.d/$1 start ${debug}"
        if [  "$?" != 0  ]; then
            echo "${1^} could not be started."
            exit 1;
        else
            echo "${1^} started"
        fi             
    else
        echo "Error: ${1^} could not start. No service manager found on the system."
        exit 1;
    fi

}

## Show script usage
getHelp() {

   echo ""
   echo "Usage: $0 arguments"
   echo -e "\t-d   | --debug Shows the complete installation output"
   echo -e "\t-i   | --ignore-health-check Ignores the health-check"
   echo -e "\t-h   | --help Shows help"
   exit 1 # Exit script after printing help

}

## Download all the necessary packages
downloadPackages() {
    logger "Downloading packages..."
    mkdir ~/wazuh-packages
    cd ~/wazuh-packages
    PACKAGES=$(pwd)
    if [ ${sys_type} == "yum" ] || [ ${sys_type} == "zypper" ]; then    
        eval "curl -so ~/wazuh-packages/wazuh-manager-4.0.0-1.x86_64.rpm https://packages.wazuh.com/4.x/yum/wazuh-manager-4.0.4-1.x86_64.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistroforelasticsearch-1.11.0.rpm https://packages.wazuh.com/4.x/yum/opendistroforelasticsearch-1.11.0.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/elasticsearch-oss-7.9.1-x86_64.rpm https://packages.wazuh.com/4.x/yum/elasticsearch-oss-7.9.1-x86_64.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-sql-1.11.0.0-1.noarch.rpm https://packages.wazuh.com/4.x/yum/opendistro-sql-1.11.0.0-1.noarch.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-alerting-1.11.0.1-1.noarch.rpm https://packages.wazuh.com/4.x/yum/opendistro-alerting-1.11.0.1-1.noarch.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-job-scheduler-1.11.0.0-1.noarch.rpm https://packages.wazuh.com/4.x/yum/opendistro-job-scheduler-1.11.0.0-1.noarch.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-security-1.11.0.0.rpm https://packages.wazuh.com/4.x/yum/opendistro-security-1.11.0.0.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-performance-analyzer-1.11.0.0-1.noarch.rpm https://packages.wazuh.com/4.x/yum/opendistro-performance-analyzer-1.11.0.0-1.noarch.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-index-management-1.11.0.0-1.noarch.rpm https://packages.wazuh.com/4.x/yum/opendistro-index-management-1.11.0.0-1.noarch.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-knn-1.11.0.0-1.noarch.rpm https://packages.wazuh.com/4.x/yum/opendistro-knn-1.11.0.0-1.noarch.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-knnlib-1.11.0.0-1_linux.x86_64.rpm https://packages.wazuh.com/4.x/yum/opendistro-knnlib-1.11.0.0-1_linux.x86_64.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-anomaly-detection-1.11.0.0-1.noarch.rpm https://packages.wazuh.com/4.x/yum/opendistro-anomaly-detection-1.11.0.0-1.noarch.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/filebeat-oss-7.9.1-x86_64.rpm https://packages.wazuh.com/4.x/yum/filebeat-oss-7.9.1-x86_64.rpm --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistroforelasticsearch-kibana-1.11.0.rpm https://packages.wazuh.com/4.x/yum/opendistroforelasticsearch-kibana-1.11.0.rpm --max-time 300 ${debug}"
    elif [ ${sys_type} == "apt-get" ]; then
        eval "curl -so ~/wazuh-packages/wazuh-manager_4.0.4-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-manager/wazuh-manager_4.0.4-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistroforelasticsearch_1.11.0-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistroforelasticsearch/opendistroforelasticsearch_1.11.0-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/elasticsearch-oss-7.9.1-amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/e/elasticsearch-oss/elasticsearch-oss-7.9.1-amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-sql_1.11.0.0-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-sql/opendistro-sql_1.11.0.0-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-alerting_1.11.0.1-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-alerting/opendistro-alerting_1.11.0.1-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-job-scheduler_1.11.0.0-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-job-scheduler/opendistro-job-scheduler_1.11.0.0-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-security-1.11.0.0.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-security/opendistro-security-1.11.0.0.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-performance-analyzer_1.11.0.0-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-performance-analyzer/opendistro-performance-analyzer_1.11.0.0-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-index-management_1.11.0.0-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-index-management/opendistro-index-management_1.11.0.0-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-knn_1.11.0.0-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-knn/opendistro-knn_1.11.0.0-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-knnlib_1.11.0.0_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-knnlib/opendistro-knnlib_1.11.0.0_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistro-anomaly-detection_1.11.0.0-1_amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistro-anomaly-detection/opendistro-anomaly-detection_1.11.0.0-1_amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/filebeat-oss-7.9.1-amd64.deb https://packages.wazuh.com/4.x/apt/pool/main/f/filebeat/filebeat-oss-7.9.1-amd64.deb --max-time 300 ${debug}"
        eval "curl -so ~/wazuh-packages/opendistroforelasticsearch-kibana-1.11.0.deb https://packages.wazuh.com/4.x/apt/pool/main/o/opendistroforelasticsearch-kibana/opendistroforelasticsearch-kibana-1.11.0.deb --max-time 300 ${debug}"
    fi
    eval "curl -so ~/wazuh-packages/wazuh_kibana-4.0.4_7.9.1-1.zip https://packages.wazuh.com/4.x/ui/kibana/wazuh_kibana-4.0.4_7.9.1-1.zip --max-time 300 ${debug}"

    logger "Downloading configuration files..."
    eval "curl -so ~/wazuh-packages/elasticsearch.yml https://raw.githubusercontent.com/wazuh/wazuh-documentation/4.0/resources/open-distro/elasticsearch/7.x/elasticsearch_all_in_one.yml --max-time 300 ${debug}"
    eval "curl -so ~/wazuh-packages/roles.yml https://raw.githubusercontent.com/wazuh/wazuh-documentation/4.0/resources/open-distro/elasticsearch/roles/roles.yml --max-time 300 ${debug}"
    eval "curl -so ~/wazuh-packages/roles_mapping.yml https://raw.githubusercontent.com/wazuh/wazuh-documentation/4.0/resources/open-distro/elasticsearch/roles/roles_mapping.yml --max-time 300 ${debug}"
    eval "curl -so ~/wazuh-packages/internal_users.yml https://raw.githubusercontent.com/wazuh/wazuh-documentation/4.0/resources/open-distro/elasticsearch/roles/internal_users.yml --max-time 300 ${debug}"  
    eval "curl -so ~/wazuh-packages/search-guard-tlstool-1.8.zip https://maven.search-guard.com/search-guard-tlstool/1.8/search-guard-tlstool-1.8.zip --max-time 300 ${debug}"
    eval "unzip ~/wazuh-packages/search-guard-tlstool-1.8.zip -d ~/wazuh-packages/searchguard ${debug}"
    eval "curl -so ~/wazuh-packages/searchguard/search-guard.yml https://raw.githubusercontent.com/wazuh/wazuh-documentation/4.0/resources/open-distro/searchguard/search-guard-aio.yml --max-time 300 ${debug}"  
    eval "curl -so ~/wazuh-packages/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh-documentation/4.0/resources/open-distro/filebeat/7.x/filebeat_all_in_one.yml --max-time 300  ${debug}"
    eval "curl -so ~/wazuh-packages/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/4.0/extensions/elasticsearch/7.x/wazuh-template.json --max-time 300 ${debug}"
    eval "curl -so ~/wazuh-packages/wazuh-filebeat-0.1.tar.gz https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.1.tar.gz --max-time 300 ${debug}" 
    eval "curl -so ~/wazuh-packages/kibana.yml https://raw.githubusercontent.com/wazuh/wazuh-documentation/4.0/resources/open-distro/kibana/7.x/kibana_all_in_one.yml --max-time 300 ${debug}"
    eval "curl -so ~/wazuh-packages/wazuh_kibana-4.0.4_7.9.1-1.zip https://packages.wazuh.com/4.x/ui/kibana/wazuh_kibana-4.0.4_7.9.1-1.zip --max-time 300 ${debug}"
}

## Wazuh manager
installWazuh() {
    
    logger "Installing the Wazuh manager..."
    if [ ${sys_type} == "yum" ] || [ ${sys_type} == "zypper" ]; then  
        eval "yum install  -y ~/wazuh-packages/wazuh-manager-4.0.0-1.x86_64.rpm ${debug}"
    elif [ ${sys_type} == "apt-get" ]; then
        eval "apt install -y ~/wazuh-packages/wazuh-manager_4.0.4-1_amd64.deb ${debug}"
    fi
    if [  "$?" != 0  ]; then
        echo "Error: Wazuh installation failed"
        exit 1;
    else
        logger "Done"
    fi   
    startService "wazuh-manager"

}

## Elasticsearch
installElasticsearch() {

    logger "Installing Open Distro for Elasticsearch..."

    if [ ${sys_type} == "yum" ] || [ ${sys_type} == "zypper" ]; then  
        eval "yum install -y  ~/wazuh-packages/elasticsearch-oss-* ${debug}"
        eval "yum install -y ~/wazuh-packages/opendistro-* ${debug}"
        eval "yum install -y ~/wazuh-packages/opendistroforelasticsearch-1* ${debug}"
    elif [ ${sys_type} == "apt-get" ]; then
        eval "apt install -y ~/wazuh-packages/elasticsearch-oss-* ${debug}"
        eval "apt install -y ~/wazuh-packages/opendistro-* ${debug}"
        eval "apt install -y ~/wazuh-packages/opendistroforelasticsearch_* ${debug}"
    fi

    if [  "$?" != 0  ]; then
        echo "Error: Elasticsearch installation failed"
        exit 1;
    else
        logger "Done"

        logger "Configuring Elasticsearch..."

        mv ~/wazuh-packages/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
        mv ~/wazuh-packages/roles.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles.yml
        mv ~/wazuh-packages/roles_mapping.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles_mapping.yml
        mv ~/wazuh-packages/internal_users.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml

        eval "rm /etc/elasticsearch/esnode-key.pem /etc/elasticsearch/esnode.pem /etc/elasticsearch/kirk-key.pem /etc/elasticsearch/kirk.pem /etc/elasticsearch/root-ca.pem -f ${debug}"
        eval "mkdir /etc/elasticsearch/certs ${debug}"
        eval "cd /etc/elasticsearch/certs ${debug}"
        mv ~/wazuh-packages/searchguard ~/searchguard
        mv ~/wazuh-packages/searchguard/search-guard.yml ~/searchguard/
        eval "chmod +x ~/searchguard/tools/sgtlstool.sh ${debug}"
        eval "bash ~/searchguard/tools/sgtlstool.sh -c ~/searchguard/search-guard.yml -ca -crt -t /etc/elasticsearch/certs/ ${debug}"
        if [  "$?" != 0  ]; then
            echo "Error: certificates were not created"
            exit 1;
        else
            logger "Certificates created"
        fi     
        eval "rm /etc/elasticsearch/certs/client-certificates.readme /etc/elasticsearch/certs/elasticsearch_elasticsearch_config_snippet.yml ~/search-guard-tlstool-1.8.zip -f ${debug}"
        
        # Configure JVM options for Elasticsearch
        ram_gb=$(free -g | awk '/^Mem:/{print $2}')
        ram=$(( ${ram_gb} / 2 ))

        if [ ${ram} -eq "0" ]; then
            ram=1;
        fi    
        eval "sed -i "s/-Xms1g/-Xms${ram}g/" /etc/elasticsearch/jvm.options ${debug}"
        eval "sed -i "s/-Xmx1g/-Xmx${ram}g/" /etc/elasticsearch/jvm.options ${debug}"

        jv=$(java -version 2>&1 | grep -o -m1 '1.8.0' )
        if [ "${jv}" == "1.8.0" ]; then
            ln -s /usr/lib/jvm/java-1.8.0/lib/tools.jar /usr/share/elasticsearch/lib/
            echo "root hard nproc 4096" >> /etc/security/limits.conf 
            echo "root soft nproc 4096" >> /etc/security/limits.conf 
            echo "elasticsearch hard nproc 4096" >> /etc/security/limits.conf 
            echo "elasticsearch soft nproc 4096" >> /etc/security/limits.conf 
            echo "bootstrap.system_call_filter: false" >> /etc/elasticsearch/elasticsearch.yml
        fi      

        # Start Elasticsearch
        startService "elasticsearch"
        echo "Initializing Elasticsearch..."
        until $(curl -XGET https://localhost:9200/ -uadmin:admin -k --max-time 120 --silent --output /dev/null); do
            echo -ne ${char}
            sleep 10
        done    

        eval "cd /usr/share/elasticsearch/plugins/opendistro_security/tools/ ${debug}"
        eval "./securityadmin.sh -cd ../securityconfig/ -nhnv -cacert /etc/elasticsearch/certs/root-ca.pem -cert /etc/elasticsearch/certs/admin.pem -key /etc/elasticsearch/certs/admin.key ${debug}"

        echo "Done"
    fi

}

## Filebeat
installFilebeat() {
    
    logger "Installing Filebeat..."
    
    if [ ${sys_type} == "yum" ] || [ ${sys_type} == "zypper" ]; then  
        eval "yum install -y  ~/wazuh-packages/filebeat-oss* ${debug}"
    elif [ ${sys_type} == "apt-get" ]; then
        eval "apt install -y ~/wazuh-packages/filebeat-oss* ${debug}"
    fi
    if [  "$?" != 0  ]; then
        echo "Error: Filebeat installation failed"
        exit 1;
    else
        mv ~/wazuh-packages/filebeat.yml /etc/filebeat/
        mv ~/wazuh-packages/wazuh-template.json /etc/filebeat/
        
        eval "chmod go+r /etc/filebeat/wazuh-template.json ${debug}"
        eval "tar -xvz -C /usr/share/filebeat/module -f ~/wazuh-packages/wazuh-filebeat-0.1.tar.gz ${debug}"
        eval "mkdir /etc/filebeat/certs ${debug}"
        eval "cp /etc/elasticsearch/certs/root-ca.pem /etc/filebeat/certs/ ${debug}"
        eval "mv /etc/elasticsearch/certs/filebeat* /etc/filebeat/certs/ ${debug}"

        # Start Filebeat
        startService "filebeat"

        logger "Done"
    fi

}

## Kibana
installKibana() {
    
    logger "Installing Open Distro for Kibana..."
    if [ ${sys_type} == "yum" ] || [ ${sys_type} == "zypper" ]; then  
        eval "yum install -y  ~/wazuh-packages/opendistroforelasticsearch-kibana* ${debug}"
    elif [ ${sys_type} == "apt-get" ]; then
        eval "apt install -y ~/wazuh-packages/opendistroforelasticsearch-kibana* ${debug}"
    fi
    if [  "$?" != 0  ]; then
        echo "Error: Kibana installation failed"
        exit 1;
    else    
        mv ~/wazuh-packages/kibana.yml /etc/kibana/
        eval "chown -R kibana:kibana /usr/share/kibana/optimize ${debug}"
        eval "chown -R kibana:kibana /usr/share/kibana/plugins ${debug}"
        eval "cd /usr/share/kibana ${debug}"
        eval "sudo -u kibana bin/kibana-plugin install file:///$PACKAGES/wazuh_kibana-4.0.4_7.9.1-1.zip ${debug}"
        if [  "$?" != 0  ]; then
            echo "Error: Wazuh Kibana plugin could not be installed."
            exit 1;
        fi     
        eval "mkdir /etc/kibana/certs ${debug}"
        eval "mv /etc/elasticsearch/certs/kibana_http.key /etc/kibana/certs/kibana.key ${debug}"
        eval "mv /etc/elasticsearch/certs/kibana_http.pem /etc/kibana/certs/kibana.pem ${debug}"
        eval "cp /etc/elasticsearch/certs/root-ca.pem /etc/kibana/certs/ ${debug}"
        eval "setcap 'cap_net_bind_service=+ep' /usr/share/kibana/node/bin/node ${debug}"

        # Start Kibana
        startService "kibana"

        logger "Done"
    fi

}

## Health check
healthCheck() {

    cores=$(cat /proc/cpuinfo | grep processor | wc -l)
    ram_gb=$(free -m | awk '/^Mem:/{print $2}')

    if [ ${cores} -lt 2 ] || [ ${ram_gb} -lt 3700 ]; then
        echo "Your system does not meet the recommended minimum hardware requirements of 4Gb of RAM and 2 CPU cores. If you want to proceed with the installation use the -i option to ignore these requirements."
        exit 1;
    elif [[ -f /etc/elasticsearch/elasticsearch.yml ]] && [[ -f /etc/kibana/kibana.yml ]] && [[ -f /etc/filebeat/filebeat.yml ]]; then
        echo "All the componens have already been installed."
        exit 1;
    else
        echo "Starting the installation..."
    fi

}

checkInstallation() {

    logger "Checking the installation..."
    eval "curl -XGET https://localhost:9200 -uadmin:admin -k --max-time 300 ${debug}"
    if [  "$?" != 0  ]; then
        echo "Error: Elasticsearch was not successfully installed."
        exit 1;     
    else
        echo "Elasticsearch installation succeeded."
    fi
    eval "filebeat test output ${debug}"
    if [  "$?" != 0  ]; then
        echo "Error: Filebeat was not successfully installed."
        exit 1;     
    else
        echo "Filebeat installation succeeded."
    fi    
    logger "Initializing Kibana (this may take a while)"
    until [[ "$(curl -XGET https://localhost/status -I -uadmin:admin -k -s --max-time 300 | grep "200 OK")" ]]; do
        echo -ne $char
        sleep 10
    done    
    echo $'\nInstallation finished'
    echo $'\nYou can access the web interface https://<kibana_ip>. The credentials are admin:admin'
    exit 0;

}

main() {

    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root."
        exit 1;
    fi   

    checkArch 

    if [ -n "$1" ]; then      
        while [ -n "$1" ]
        do
            case "$1" in 
            "-i"|"--ignore-healthcheck") 
                ignore=1          
                shift 1
                ;; 
            "-d"|"--debug") 
                debugEnabled=1          
                shift 1
                ;;  
            "-p"|"--download-packages") 
                packages=1          
                shift 1
                ;;                                                 
            "-h"|"--help")        
                getHelp
                ;;                                         
            *)
                getHelp
            esac
        done    

        if [ -n "${debugEnabled}" ]; then
            debug=""
        fi
        
        if [ -n "${ignore}" ]; then
            echo "Health-check ignored."    
        else
            healthCheck           
        fi    
        if [ -n "${packages}" ]; then
            downloadPackages           
        fi                     
        installWazuh
        installElasticsearch
        installFilebeat
        installKibana
        checkInstallation    
    else
        healthCheck   
        installWazuh
        installElasticsearch
        installFilebeat
        installKibana
        checkInstallation  
    fi

}

main "$@"