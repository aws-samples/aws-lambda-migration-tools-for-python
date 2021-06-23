#!/bin/bash
while getopts 'ht:f:r:' args; do
	case ${args} in
		 h)
	        echo "Pull an inventory report on Lambda published versions, alias and Runtimes.";
	        echo "Usage:";
	        echo "lambda-inventory.sh -r <REGION> [-f <FUNCTION NAME>]";
	        echo "REGION: Region where resources are located.";
	        echo "FUNCTION NAME: Name of function or functions to be pulled, if multiple are specified, enter them between \" \" and separated by spaces: \"fun1 fun2 fun3\". "
	        exit;;
	    r) region=${OPTARG};;
		t) tag=${OPTARG};;
		f) functionName+=(${OPTARG});;
		:) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
	esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$region" ]; then
        echo 'Region not specified.' >&2
        echo 'Try: lambda-modernize.sh -h'
        exit 1
fi


if ! [ -x "$(command -v aws)" ]; then
  echo 'Error: AWS CLI is not installed or properly configured.' >&2
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed or properly configured.' >&2
  exit 1
fi

if [ ${#functionName} -gt 0 ]; then
	for val in "${functionName[@]}"; do
    	list+=($val)
	done
else
	echo "Pulling full list"
	list=($(aws lambda list-functions --region $region| jq -r '.Functions|map(.FunctionName)|.[]'))
fi


for func in "${!list[@]}"
do
	funcVersions=($(aws lambda list-versions-by-function --region $region --function-name ${list[func]}|jq -c '.Versions|map({"Version":(.Version),"Runtime":.Runtime})|.[]'))
	funcAlias=$(aws lambda list-aliases --function-name ${list[func]} --region $region |jq -r '.Aliases|map({"FunctionVersion":(.FunctionVersion),"Name":.Name})')
	echo "============================="
	echo "Function: ${list[func]}"
	echo "----------------------------"
	echo "Version ---- Runtime ---- Alias"
	for version in "${funcVersions[@]}"
	do
		publishedVersion=$(echo ${version[Version]}|jq -r '.Version')
		echo -e "$publishedVersion -- $(echo ${version[Runtime]}|jq -r '.Runtime') -- $(echo $funcAlias|jq  --arg version "$publishedVersion" -r 'map(select(.FunctionVersion==$version))|map(.Name)|.[]')"
		
	done
done

unset list
unset region
unset tag
unset functionName



