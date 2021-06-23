#!/bin/bash
while getopts ht:r:f:m args; do
case ${args} in
	 h)
        echo "Analyze and migrate lambda functions with associated tag.";
        echo "Usage:";
        echo "lambda-modernize.sh -t <Tag Key> -r <Region> -m "
        echo "TAG: String for tag key specified in Lambda functions to be analyzed, must be set to true in Lambda. Make sure only alphanumeric characters are used."
        echo "REGION: Region where resources are located"
        echo "MIGRATE: When specified, Lambda code is refactored to Python 3.x and uploaded back to Lambda function. Without it, only a report of the function is provided."
        exit;;
    r) region=${OPTARG};;
	t) tag=${OPTARG};;
	f) functionName+=(${OPTARG});;
	m) migrate=true;;
	:) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$tag" ]; then
        echo 'Tag not specified.' >&2
        echo 'Try: lambda-modernize.sh -h'
        exit 1
fi

if [ -z "$migrate" ]; then
        migrate=false
fi

if [ -z "$region" ]; then
        echo 'Region not specified.' >&2
        echo 'Try: lambda-modernize.sh -h'
        exit 1
fi


if ! [ -x "$(command -v aws)" ]; then
  echo 'Error: AWS CLI is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v pylint)" ]; then
  echo 'Error: pylint is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v 2to3)" ]; then
  echo 'Error: 2to3 is not installed.' >&2
  exit 1
fi

if [ -d "$tag" ]; then
	echo "Error: Directory with name -$tag- already exists. Move directory first" >&2
	exit 1
fi

if [ ${#functionName} -gt 0 ]; then
	echo "==========================="
	echo "Mapping specific functions"
	for val in "${functionName[@]}"; do
    	list+=($val)
	done
else
	echo "==========================="
	echo "Mapping Python 2.7 Functions with tag $tag"

	list=($(aws lambda list-functions --region $region --query 'Functions[?starts_with(Runtime, `python2.7`) == `true`]'| jq -r 'if length!=0 then map(.FunctionName)|.[] else .[] end'))
fi

mkdir $tag
cd $tag

if ! [ -z "$list" ]; then
	for f in "${list[@]}"
	do
		echo ":Working on function: $f"
		echo "==========================="
		funcArn=$(aws lambda get-function --region $region --function-name $f|jq -r '.Configuration.FunctionArn')
		migrationTag=$(aws lambda list-tags --region $region --resource $funcArn|jq -r --arg tag "$tag" 'if .Tags[$tag] then .Tags[$tag] else false end')
		if [[ $migrationTag = "True" || $migrationTag = "true" ]]
		then
			echo "==Downloading code for: $f"
			mkdir $f
			cd $f
			aws lambda publish-version --function-name $f --region $region
			curl -o $f.zip $(aws lambda get-function --region $region --function-name $f|jq -r '.Code.Location')
			unzip $f
			rm $f.zip
			echo "==Generating analysis report"
			pylint *.py --output=../$f-PylintReport.txt
			if $migrate
			then
				echo "===Creating compatible version"
				2to3 . -w
				zip -r $f.zip . -x *.bak
				echo "===Publishing existing version"
				aws lambda publish-version --function-name $f --region $region
				echo "===Updating code"
				aws lambda update-function-code --function-name $f --zip-file fileb://$f.zip --region $region
				echo "===Modifying runtime configuration"
				aws lambda update-function-configuration --function-name $f --runtime "python3.8" --region $region
				aws lambda tag-resource --resource $funcArn --tags "$tag-Completed=True" --region $region
				aws lambda tag-resource --resource $funcArn --tags "$tag=False" --region $region
				migratedVersion=$(aws lambda publish-version --function-name $f --region $region| jq -r '.Version')
			fi
			cd ..
		else
			echo "==Not Tagged for migration"
			echo "-------------------------"
		fi
	done
fi
echo "==========================="
echo "Finalized"
echo "==========================="
cd ..

