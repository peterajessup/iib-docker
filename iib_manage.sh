#!/bin/bash
# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e

NODE_NAME=${NODE_NAME-IIBV1007}
EXEC_NAME=IS1
export JDBC_SERVICE=BROKER


stop()
{
	echo "----------------------------------------"
	echo "Stopping node $NODE_NAME..."
	mqsistop $NODE_NAME
}



start()
{
	echo "----------------------------------------"
  /opt/ibm/iib-10.0.0.7/iib version
	echo "----------------------------------------"

  NODE_EXISTS=`mqsilist | grep $NODE_NAME > /dev/null ; echo $?`
  
  


	if [ ${NODE_EXISTS} -ne 0 ]; then
    echo "----------------------------------------"
    echo "Node $NODE_NAME does not exist..."
    echo "Creating node $NODE_NAME"
		mqsicreatebroker $NODE_NAME
		mqsistart $NODE_NAME
		mqsicreateexecutiongroup $NODE_NAME $EXEC_NAME
		mqsistop $NODE_NAME
		
    echo "----------------------------------------"
	fi
	echo "----------------------------------------"
	echo "Starting syslog"
  sudo /usr/sbin/rsyslogd
  	
  	echo "Configuring db access"
  	mqsisetdbparms $NODE_NAME -n jdbc::sql1 -u sa -p passw0rd
  	mqsisetdbparms $NODE_NAME -n BROKER -u sa -p passw0rd
  	
	echo "Starting node $NODE_NAME"
  	
  	mqsistart $NODE_NAME
	echo "----------------------------------------"

	SERVICE_EXISTS=`mqsireportproperties $NODE_NAME -c JDBCProviders -o $JDBC_SERVICE -n Name > /dev/null ; echo $?`
	
	echo $SERVICE_EXISTS
	
	if [ ${SERVICE_EXISTS} -ne 0 ] ; then
		echo "Creating Configurable Service "$JDBC_SERVICE
		
		mqsicreateconfigurableservice $NODE_NAME -c JDBCProviders -o $JDBC_SERVICE -n type4DatasourceClassName,type4DriverClassName,databaseType,jdbcProviderXASupport,portNumber,connectionUrlFormatAttr5,connectionUrlFormatAttr4,serverName,connectionUrlFormatAttr3,connectionUrlFormatAttr2,connectionUrlFormatAttr1,environmentParms,maxConnectionPoolSize,description,jarsURL,databaseName,databaseVersion,securityIdentity,connectionUrlFormat,databaseSchemaNames -v "com.microsoft.sqlserver.jdbc.SQLServerXADataSource","com.microsoft.sqlserver.jdbc.SQLServerDriver","Microsoft SQL Server","true","16152","","","cap-sg-prd-2.integration.ibmcloud.com","","","","default_none","0","default_Description","default_Path","BROKER","default_Database_Version","sql2","jdbc:sqlserver://[serverName]:[portNumber];DatabaseName=[databaseName];user=[user];password=[password]","useProvidedSchemaNames"

  	fi
  	
  	
  	echo "Starting Switch Server"
  	
  	SWITCH_EXISTS=`iibswitch update switch -c /home/iibuser/switch.json > /dev/null ; echo $?`
  	
  	if [ ${SWITCH_EXISTS} -ne 0 ] ; then
  		echo "Creating and starting Switch"
  		iibswitch create switch -c /home/iibuser/switch.json
  		
  	fi
  	mqsichangeproperties $NODE_NAME -e $EXEC_NAME –o ComIbmIIBSwitchManager -n agentXConfigFile –p /home/iibuser/agentx.json
  	
  	mqsistop $NODE_NAME
  	mqsistart $NODE_NAME
  	
  	
  	
}

monitor()
{
	echo "----------------------------------------"
	echo "Running - stop container to exit"
	# Loop forever by default - container must be stopped manually.
  # Here is where you can add in conditions controlling when your container will exit - e.g. check for existence of specific processes stopping or errors beiing reported
	while true; do
		sleep 1
	done
}

iib-license-check.sh
start
trap stop SIGTERM SIGINT
monitor
