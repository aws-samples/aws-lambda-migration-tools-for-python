# AWS Lambda Functions Migration Tools for Python

Tools to automate Python 2.7 to 3.8 migration activities. These tools facilite function inventory creation and code porting to Python 3.8. 

The script `lambda-inventory` pulls versions and associated aliases from the functions on a specified version and prints them on screen.
The script `lambda-migrate` is based on Python pylint and 2to3 to get code assesments and code porting to 3.8 and performs code corrections for fixers defined in 2to3 on your .py files. It does not include layers and imported libraries on the assesment.

## Requirements
### Terminal Access
Console access with BASH 3.2 or newer. You can use AWS CloudShell with the proper credentials and the additional requirements.

### AWS CLI 
Proper credentials to list functions, pull configuration, upload code and change runtime configuration.

### Pylint
https://www.pylint.org/

### 2to3
https://docs.python.org/3/library/2to3.html

### jq
https://stedolan.github.io/jq/

Make sure all these tools can be invoked from the command line before you continue.


### Published Lambdas
The tool will perform a best effort migration attempt, yet, proper testing is required before changes are placed in production. The tool will publish the existing 2.7 version as a means to ensure previous state is preserved for rollback. Make sure deployed Lambda functions have stable versions already published with alias defined and interactions are done with the specific versions or alias.

## What the lambda-inventory script does
1. The script iterates over specified functions or over all the functions in the specified region.
2. For each function, the script will pull published versions, associated runtimes and alias.
3. Results are printed on screen for each function.

## What the lambda-migrate script does
1. The script looks for Python2.7 lambda functions on the specified region marked with a specific tag (specified at execution time). Create a tag on existing Python 2.x Lambda functions to select the ones to be analyzed.
2. The script publishes the existing code as a new version to make sure there's a way to roll back. Make sure existing applications are pointing to a published version with an alias.
3. The script provides 2 modalities: Generating a report of findings using pylint and fixing incompatible lines of code. The opperation mode is specified with the -m flag. Without the -m flag, the code will only be analyzed and no changes are generated. Specifying the -m flag will instruct the code to make changes based on 2to3 fixers.
4. For both opperation mdoes, code is analyzed locally, and a text file report per function is generated.
5. If the -m flag is provided, the script ports the function code to Python 3.8 based on 2to3 fixers, creates a zip file and uploads it back again to the function. A new version is published.

### Usage - Inventory
Download the script, make sure you have the requirements section covered and change permissions to execute on the script:

`chmod +x lambda-inventory.sh`

Execute script:

`./lambda-inventory.sh -r [REGION] [-f [FUNCTION]]`

-r: REGION where functions are located (such as: us-east-1)
-f: FUNCTION names you can specify a single function name or multiple enclosed in "" and separated by spaces.

Examples:

To get an inventory from all Lambda functions in US-EAST-1:

`./lambda-inventory.sh -r us-east-1`

### Usage - Code Assesment
Download the script, make sure you have the requirements section covered and change permissions to execute on the script:

`chmod +x lambda-migrate.sh`

Execute script:

`./lambda-migrate.sh -t [TAG] -r [REGION] [-f [FUNCTION(S)]]`

-t: TAG used to discriminate Lambda functions to be analyzed.
-f: FUNCTION names. You can specify a single function name or multiple names separated by spaces and enclosed in " ".
-r: REGION where functions are located (such as: us-east-1)

Examples:

To analyze functions and get a pylint report using a tag `migrate3x` in US-EAST-1:

`./lambda-migrate.sh -t migrate3x -r us-east-1`

To analyze "Function1", "Function2" and "Function3" Lambda functions and get a pylint report using a tag "migrate3x" in US-EAST-1:

`./lambda-migrate.sh -t migrate3x -r us-east-1 -m`



### Usage - Migration
Download the script, make sure you have the requirements section covered and change permissions to execute on the script:

`chmod +x lambda-migrate.sh`

Execute script:

`./lambda-migrate.sh -t [TAG] -r [REGION] [-f [FUNCTION(S)] -m]`

-t: TAG used to discriminate Lambda functions to be ported.
-f: FUNCTION names you can specify a single function name or multiple enclosed in "" and separated by spaces.  
-r: REGION where functions are located (such as: us-east-1)
-m: Migrate Flag, include this to port functions. If omitted only reports based on pylint will be generated. Including this flag, changes will be pushed to the region.

Examples:

To analyze functions and get a pylint report using a tag `migrate3x` in US-EAST-1:

`./lambda-migrate.sh -t migrate3x -r us-east-1`

To analyze and port code to Python3.8:

`./lambda-migrate.sh -t migrate3x -r us-east-1 -m`

