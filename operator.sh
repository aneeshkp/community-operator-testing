#!/bin/sh
source="https://github.com/operator-framework/community-operators.git"
OPERATOR_DIRECTORY="$HOME/tigeroperators"
ACTION=SETUP
#export OPERATOR_TYPE="community-operators" 
#export OPERATOR_NAME="NONAMEOPERATOR"
#export BRANCH_NAME="master"
#export PULL_ID=0
#export AUTH_TOKEN=""
#export PACKAGE_NAME=""

error(){
    msg=$1
    printf "Error occured %s" "$msg"
    echo "$1"
}
#*********************************************
# Print kubectl commands to isntall marketplace and olm required for testing "
#*********************************************
olminstallFunc(){
    if [ "$OPERATOR_TYPE" = "upstream-community-operators" ] 
    then
       echo "  
       INSTALL OLM
       ----------------------
       kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.10.0/crds.yaml
       kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.10.0/olm.yaml

       INSTALL MARKET PLACE
       ----------------------  
       (find it here $OPERATOR_DIRECTORY/$OPERATOR_NAME/)

       kubectl apply -f $OPERATOR_NAME/operator-marketplace/deploy/upstream/

       "
    fi 
}
#*********************************************
# Sets up operator  1. Creating folder , 2) cloning git 3) fetching PR 4)  and 5) switching to branch
#*********************************************
setupOperatorFunction(){
    # Begin script in case all parameters are correct
    if [ -d "$OPERATOR_DIRECTORY" ] 
    then
        printf "Directory %s exists.\n" "$OPERATOR_DIRECTORY"
    else
        printf "Error: Directory %s does not exists.\n" "$OPERATOR_DIRECTORY"
        read -p "Do you want to create directory $OPERATOR_DIRECTORY? " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
        # do dangerous stuff
        mkdir "$OPERATOR_DIRECTORY"
        print " Directory $OPERATOR_DIRECTORY created.\n"
        else
             error "Exiting ......."
             return
        fi
    fi

    if [ -d "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME" ] 
    then
        printf "%s/%s ... cleaning up\n" "$OPERATOR_DIRECTORY" "$OPERATOR_NAME"
        rm -rf "$OPERATOR_DIRECTORY/$OPERATOR_NAME"
    fi
    printf "Directory %s does not exists. Creating new.\n" "$OPERATOR_NAME"
    mkdir "$OPERATOR_DIRECTORY/$OPERATOR_NAME"
    printf "Directory %s/%s created.\n" "$OPERATOR_DIRECTORY" "$OPERATOR_NAME"

    #Begin git  clone and PR's
    cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/ || exit
    git clone $source
    cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/community-operators || exit 
    git fetch origin pull/"$PULL_ID"/head:"$BRANCH_NAME"
    git checkout "$BRANCH_NAME"


    if [ "$OPERATOR_TYPE" = "upstream-community-operators" ]
    then
        printf "Cloning other required repo\n"
        cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/ || exit
        git clone https://github.com/operator-framework/operator-marketplace.git
        git clone https://github.com/operator-framework/operator-courier.git
        git clone https://github.com/operator-framework/operator-lifecycle-manager.git
        
        olminstallFunc
    else
        printf "Cloning other required repo (operator courier)\n"
        cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/ || exit
        git clone https://github.com/operator-framework/operator-courier.git
    fi

    printf " *----------------------------------- Done -----------------------------------*\n"
    printf "Make sure you run [pip3 install operator-courier].\n"
    ls "$OPERATOR_DIRECTORY" 
    printf "cd %s/%s/%s\n" "$OPERATOR_DIRECTORY" "$OPERATOR_NAME" "$OPERATOR_TYPE"
    cd "$OPERATOR_DIRECTORY" || exit
}

#*********************************************
# Menu option to choose operator type 1) Community or 2) Upstream Community
#*********************************************
newoperatorType(){
     echo "Select operator type 1=comunity 2=upstream for  fetching PR."
    selection=

        echo "
        CHOOSE OPERATOR TYPE
        -----------------------------
        1 - Community Operators
        2 - Upstream Community Operators
        -----------------------------
    "
    while :
    do
        echo "----------------------------"
        echo -n "Select Operator Type (1/2): "
        read selection
        echo ""
        case $selection in
            1 ) export OPERATOR_TYPE="community-operators" 
                break
                ;;
            2 ) export OPERATOR_TYPE="upstream-community-operators"
                break
                ;;
            * ) echo "Please enter 1, pr 2"
        esac
    done
    echo "You selectd operator type as $OPERATOR_TYPE"

}
#*********************************************
# Menu option to read and set the operator name from the user
#*********************************************
newoperatorName(){
    printf "OPERATOR NAME:\a"
    read operatorname
    export OPERATOR_NAME=$operatorname
}

#*********************************************
# Entry poin to NEW Operator setup
#*********************************************
newOperatorSetup(){
    ACTION=SETUP
    newoperatorType
    newoperatorName
    printf "Enter Pull ID\n"
    read pullid
    printf "Enter Branch name (The branch name you want to create):\n"
    read brnachname
    export PULL_ID=$pullid
    export BRANCH_NAME=$brnachname
    setupOperatorFunction
}

void(){
    return 
}
#*********************************************
# Sets up env variables
#*********************************************
testVariableSetup(){

    if [ -z "$OPERATOR_TYPE" ]
    then
      newoperatorType
    else
     printf "Using operator type  $OPERATOR_TYPE"  
    fi
    if [ -z "$OPERATOR_NAME" ]
    then
      newoperatorName
    else
       printf " Do you want to set up new or use existing operator\n"
       echo  "****************** $OPERATOR_NAME ***********************\a "

    selection=

        echo "
        OPERATOR TYPE MENU
        1 - Use
        2 - New
    "
    while :
    do
        echo -r "Enter selection: "
        read selection 
        echo ""
        case $selection in
            1 ) void 
                break 
                ;;
            2 ) newoperatorName
                break
                ;;
            * ) echo "Please enter 1, or 2"
        esac
    done
    
    fi  
       
}
setupQuay(){

if [ ! -z "$QUAY_TOKEN" ]
then
    echo "quay token: $QUAY_TOKEN"
    echo "Quay token already present, if you want new token clear env variable QUAY_TOKEN and run this again."
    echo -n "Username: "
    read QUAY_NAMESPACE

    
else
    echo -n "Username: "
    read QUAY_NAMESPACE
    echo -n "Password: "
    read -s PASSWORD
    echo


    quayout=$(curl -H "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d '
    {
        "user": {
            "username": "'"${QUAY_NAMESPACE}"'",
            "password": "'"${PASSWORD}"'"
        }
    }' 2>/dev/null)

    export QUAY_TOKEN=$(echo "$quayout" | jq '.token')

    if [ -z "$QUAY_TOKEN" ]
    then 
    printf "Error  logging  to quay %s\n" "$error"
    fi
fi

}

#*********************************************
# S Printing test commands 
#*********************************************
helpTestFunction(){ 
    ACTION=HELP
    useexisting=$1
    if [ "$useexisting" = 0 ]
    then   
        testVariableSetup
        echo "$OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME/"
        if [ ! -d "$OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME/" ] 
        then
             printf "****************** $OPERATOR_NAME ***********************\n"
             error "Error: Looks like you do not have the operator setup for $OPERATOR_NAME"
             return
        fi
        
        if  [ -e  "$OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME/$OPERATOR_NAME.package.yaml" ]
        then
                printf "Checking for OLM BUNDLE... exists \n"
        else
            printf "***************************************************************************************\n"
             error " OLM  bundle does not exists for oeprator $OPERATOR_NAME , please setup operator first. \n"
             return
        fi
    fi
    
    setupQuay
    if [ -z "$QUAY_TOKEN" ]
    then 
     printf "Couldn't get quay login.\n"
     QUAY_TOKEN="Couldn't get quay login"
    fi
    
    if  [ ! -e  "$OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME/$OPERATOR_NAME.package.yaml" ]
    then
        error " No such file or directory $OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME/$OPERATOR_NAME.package.yaml"
        return
    else
        PACKAGE_NAME="$(cat "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/community-operators/$OPERATOR_TYPE/"$OPERATOR_NAME"/*package* | grep packageName | cut -f 2 -d' ')"
        PACKAGE_VERSION="$(cat "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/community-operators/$OPERATOR_TYPE/"$OPERATOR_NAME"/*package* | grep currentCSV | cut -d'.' -f2- | cut -d'v' -f2- )"
    fi


    echo "
       TEST OPTIONS   
       -----------------------------------------------------------------------------------------------
        1 - LINTING
       
         operator-courier verify --ui_validate_io $OPERATOR_DIRECTORY/$OPERATOR_NAME/community-operators/$OPERATOR_TYPE/$OPERATOR_NAME
         

        2 - QUAY PUSHING
         operator-courier push \"""$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/community-operators/$OPERATOR_TYPE/"$OPERATOR_NAME""\" \"""$QUAY_NAMESPACE""\" \"""$PACKAGE_NAME""\" \"""$PACKAGE_VERSION""\" $QUAY_TOKEN
         
         -----------------------------------------------------------------------------------------------
         "
    
    olminstallFunc
        
}

#*********************************************
# Slapsh screen shown at the start
#*********************************************
startupMenuFunction(){
    echo "select operator setup option or test command"
    selection=
        echo "
        PROGRAM MENU
        1 - Operator Setup
        2 - Print testing commands
        
    "
    while :
    do
        echo -n "Enter your selection (1/2): "
        read  selection
        echo ""
        case $selection in
            1 ) setup 
                break 
                ;;
            2 ) helpTestFunction 0 
                break
                ;;
            * ) echo "Please enter 1 or 2"
        esac
    done

}

setup(){
    newOperatorSetup
    helpTestFunction 1
}


startupMenuFunction

