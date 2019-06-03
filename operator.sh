#!/bin/sh
helpFunction()
{
   echo ""
   echo "Usage: $0 -o parameterA -p parameterB -b parameterC"
   echo -e "\t-o , operator you are planning to test"
   echo -e "\t-p pull id from Pull Request"
   echo -e "\t-b brnachname to pull from "
   exit 1 # Exit script after printing help
}
while getopts "o:p:b:" opt
do
   case "$opt" in
      o ) parameterA="$OPTARG" ;;
      p ) parameterB="$OPTARG" ;;
      b ) parameterC="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done


# Print helpFunction in case parameters are empty
if [ -z "$parameterA" ] || [ -z "$parameterB" ] || [ -z "$parameterC" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Begin script in case all parameters are correct
source="https://github.com/operator-framework/community-operators.git"
operator_directory="$HOME/tigeroperators"
if [ -d $operator_directory ] 
then
    echo "Directory operator_directory exists" 
else
    echo "Error: Directory operator_directory does not exists."
    read -p "Do you want to create directory operator_directory? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
    # do dangerous stuff
    mkdir "$operator_directory"
    echo " Directory $operator_directory created."
    else
    exit 1
    fi
fi

if [ -d $operator_directory/$parameterA ] 
then
    echo "$operator_directory/$parameterA ... cleaning up" 
    rm -rf $operator_directory/$parameterA 
fi
 echo "Error: Directory $parameterA does not exists."
 mkdir "$operator_directory/$parameterA"
 echo " Directory $operator_directory/$parameterA created."

#Begin git  clone and PR's
cd $operator_directory/$parameterA/
git clone $source
cd $operator_directory/$parameterA/community-operators 
git fetch origin pull/$parameterB/head:$parameterC
git checkout $parameterC
echo "cd $operator_directory/$parameterA/community-operators"
