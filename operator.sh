#!/bin/sh
source="https://github.com/operator-framework/community-operators.git"
OPERATOR_DIRECTORY="$HOME/tigeroperators"
#export OPERATOR_TYPE="community-operators" 
#export OPERATOR_NAME="NONAMEOPERATOR"
#export BRANCH_NAME="master"
#export PULL_ID=0
#export AUTH_TOKEN=""
#export PACKAGE_NAME=""


helpFunction()
{
   echo ""
   echo "Usage: $0 -o parameterA -p parameterB -b parameterC  -h parameterh"
   echo -e "\t-o , operator you are planning to test"
   echo -e "\t-p pull id from Pull Request"
   echo -e "\t-b brnachname to pull from "
   echo -e "\t -h Help command"
   exit 1 # Exit script after printing help
}
helpTestFunction()
{ 
    echo "Enter your quay username"
    read QUAY_NAMESPACE
    
    PACKAGE_NAME="$(cat $OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME/*package* | grep packageName | cut -f 2 -d' ')"
    PACKAGE_VERSION="$(cat $OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME/*package* | grep currentCSV | cut -d'.' -f2- | cut -d'v' -f2- )"
    
    echo "
       TEST OPTIONS   
       -----------------------------------------------------------------------------------------------
        1 - GET Quay Token :  $OPERATOR_DIRECTORY/$OPERATOR_NAME/operator-courier/scripts/get-quay-token
         ( Then set it to export QUAY_TOKEN=""basic abcdefghijkl=="")

        2 - LINTING
       
         operator-courier verify --ui_validate_io $OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME
         

        3 - QUAY PUSHING
         operator-courier push \""$OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME"\" \""$QUAY_NAMESPACE"\" \""$PACKAGE_NAME"\" \""$PACKAGE_VERSION"\" \""$QUAY_TOKEN"\"
         
         -----------------------------------------------------------------------------------------------
         "
    if [ $OPERATOR_TYPE == "upstream-community-operators" ] 
    then
       echo "  
       INSTALL OLM
       ----------------------
       kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.10.0/crds.yaml
       kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.10.0/olm.yaml

       INSTALL MARKET PLACE
       ----------------------  
       (find it here $OPERATOR_DIRECTORY/$OPERATOR_NAME/)

       kubectl apply -f operator-marketplace/deploy/upstream/

       "
    fi 
         
        
}

operatorSetup(){
 echo "select operator type 1=comunity 2=upstream for  fetching PR or use 3 for testing help."
    selection=

        echo "
        OPERATOR TYPE MENU
        1 - Community Operators
        2 - Upstream Community Operators
    "
        echo -n "Enter selection: "
        read selection
        echo ""
        case $selection in
            1 ) export OPERATOR_TYPE="community-operators" ;;
            2 ) export OPERATOR_TYPE="upstream-community-operators" ;;
            * ) echo "Please enter 1, pr 2"
        esac
    echo "You selectd operator type as $OPERATOR_TYPE"

    echo "Enter OpertorName"
    read operatorname
    export OPERATOR_NAME=$operatorname
    echo "Enter Pull ID"
    read pullid
    export PULL_ID=$pullid
    echo "Enter PR branch name"
    read branchname
    export BRANCH_NAME=$branchname
    setupOperatorFunction
    
}

startupMenuFunction(){
    echo "select operator setup option or test command"
    selection=
        echo "
        PROGRAM MENU
        1 - Operator Setup
        2 - Print testing commands
        
    "
        echo -n "Enter selection: "
        read selection
        echo ""
        case $selection in
            1 ) operatorSetup ;;
            2 ) helpTestFunction ;;
            * ) echo "Please enter 1 or 2"
        esac

}

startupMenuFunction

setupOperatorFunction(){
    # Begin script in case all parameters are correct
    if [ -d $OPERATOR_DIRECTORY ] 
    then
        echo "Directory OPERATOR_DIRECTORY exists" 
    else
        echo "Error: Directory OPERATOR_DIRECTORY does not exists."
        read -p "Do you want to create directory OPERATOR_DIRECTORY? " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
        # do dangerous stuff
        mkdir "$OPERATOR_DIRECTORY"
        echo " Directory $OPERATOR_DIRECTORY created."
        else
        exit 1
        fi
    fi

    if [ -d $OPERATOR_DIRECTORY/$OPERATOR_NAME ] 
    then
        echo "$OPERATOR_DIRECTORY/$OPERATOR_NAME ... cleaning up" 
        rm -rf $OPERATOR_DIRECTORY/$OPERATOR_NAME 
    fi
    echo "Error: Directory $OPERATOR_NAME does not exists."
    mkdir "$OPERATOR_DIRECTORY/$OPERATOR_NAME"
    echo " Directory $OPERATOR_DIRECTORY/$OPERATOR_NAME created."

    #Begin git  clone and PR's
    cd $OPERATOR_DIRECTORY/$OPERATOR_NAME/
    git clone $source
    cd $OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators 
    git fetch origin pull/$PULL_ID/head:$BRANCH_NAME
    git checkout $BRANCH_NAME


    if [ $OPERATOR_TYPE == "upstream-community-operators" ]
    then
        echo "pulling other required repo"
        cd $OPERATOR_DIRECTORY/$OPERATOR_NAME/
        git clone https://github.com/operator-framework/operaoperator-courier push OPERATOR_DIR QUAY_NAMESPACE PACKAGE_NAME PACKAGE_VERSION TOKEN
        git clone https://github.com/operator-framework/operaoperator-courier push OPERATOR_DIR QUAY_NAMESPACE PACKAGE_NAME PACKAGE_VERSION TOKEN
        git clone https://github.com/operator-framework/operaoperator-courier push OPERATOR_DIR QUAY_NAMESPACE PACKAGE_NAME PACKAGE_VERSION TOKENit
    else
        echo "pulling other required repo (operator courier)"operator-courier push OPERATOR_DIR QUAY_NAMESPACE PACKAGE_NAME PACKAGE_VERSION TOKEN
        cd $OPERATOR_DIRECTORY/$OPERATOR_NAME/
        git clone https://github.com/operator-framework/operator-courier.git
    fi

    echo "----------------------------------- All set"
    echo "make sure you run [pip3 install operator-courier]"
    ls $OPERATOR_DIRECTORY 
    echo "cd $OPERATOR_DIRECTORY/$OPERATOR_NAME/$OPERATOR_TYPE"
    cd $OPERATOR_DIRECTORY
}
