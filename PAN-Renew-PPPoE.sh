#!/bin/bash

# AUTHOR: Engin YUCE <enginy88@gmail.com>
# DESCRIPTION: Shell script for renewing PPPoE connection to get a new IP address on PANOS.
# VERSION: 1.0
# LICENSE: Copyright 2020 Engin YUCE. Licensed under the Apache License, Version 2.0.


PAN_USERNAME="admin"
PAN_PASSWORD="admin"
PAN_IP="1.2.3.4"
PAN_INTERFACE="ethernet1/1"
PAN_VSYS="vsys1"


# BELOW THIS LINE, THERE BE DRAGONS!


_checkVariables()
{
	[[ ! -z "$PAN_USERNAME" ]] || { echo "Script variable is missing, exiting!" ; exit 1 ; }
	[[ ! -z "$PAN_PASSWORD" ]] || { echo "Script variable is missing, exiting!" ; exit 1 ; }
	[[ ! -z "$PAN_IP" ]] || { echo "Script variable is missing, exiting!" ; exit 1 ; }
	[[ ! -z "$PAN_INTERFACE" ]] || { echo "Script variable is missing, exiting!" ; exit 1 ; }
	[[ ! -z "$PAN_VSYS" ]] || { echo "Script variable is missing, exiting!" ; exit 1 ; }
}


_checkCurlAvailable()
{
	curl --version &>/dev/null
	if [[ $? != 0 ]]
	then
		echo "Error on finding curl, install the curl utility, exiting!" ; exit 1
	fi
}


_getAPIKey()
{
	local CALL=$(curl -X GET --insecure -m 5 "https://$PAN_IP/api/?type=keygen&user=$PAN_USERNAME&password=$PAN_PASSWORD" 2>/dev/null)
	if [[ $? != 0 || -z "$CALL" ]]
	then
		echo "Error on curl call, check the IP, exiting!" ; exit 1
	fi
	echo "$CALL" | grep -F "response" | grep -F "status" | grep -F "success" &>/dev/null
	if [[ $? != 0 ]]
	then
		echo "Error on curl response, check the PAN credentials, exiting!" ; exit 1
	fi
	KEY=$(echo "$CALL" | sed -n 's/.*<key>\([a-zA-Z0-9=]*\)<\/key>.*/\1/p')
	if [[ $? != 0 || X"$KEY" == X"" ]]
	then
		echo "Error on curl response, cannot parse API key, exiting!" ; exit 1
	fi
}


_callXMLAPIClearPPPoE()
{
	local CALL=$(curl -H "X-PAN-KEY: $KEY" --insecure -m 5 "https://$PAN_IP/api/?type=op&vsys=$PAN_VSYS&cmd=<clear><pppoe><interface>$PAN_INTERFACE</interface></pppoe></clear>" 2>/dev/null)
	if [[ $? != 0 || -z "$CALL" ]]
	then
		echo "Error on curl call, check the IP, exiting!" ; exit 1
	fi
	echo "$CALL" | grep -F "response" | grep -F "status" | grep -F "success" &>/dev/null
	if [[ $? != 0 ]]
	then
		echo "Error on curl response, check the interface, exiting!" ; exit 1
	fi
	echo "Clear succeeded."
}


_callXMLAPITestPPPoE()
{
	local CALL=$(curl -H "X-PAN-KEY: $KEY" --insecure -m 5 "https://$PAN_IP/api/?type=op&vsys=$PAN_VSYS&cmd=<test><pppoe><interface>$PAN_INTERFACE</interface></pppoe></test>" 2>/dev/null)
	if [[ $? != 0 || -z "$CALL" ]]
	then
		echo "Error on curl call, check the IP, exiting!" ; exit 1
	fi
	echo "$CALL" | grep -F "response" | grep -F "status" | grep -F "success" &>/dev/null
	if [[ $? != 0 ]]
	then
		echo "Error on curl response, check the interface, exiting!" ; exit 1
	fi
	echo "Test succeeded."
}


_main()
{
	_checkVariables
	_checkCurlAvailable
	echo "Attempt to renew PPPoE connection. (TIME: $(date))"
	echo "Using IP: $PAN_IP, USER: $PAN_USERNAME, INTERFACE: $PAN_INTERFACE, VSYS: $PAN_VSYS."
	_getAPIKey
	_callXMLAPIClearPPPoE
	_callXMLAPITestPPPoE
	echo "All succeeded, bye!"
}


_main
