#!/bin/sh
source="https://github.com/operator-framework/community-operators.git"
OPERATOR_DIRECTORY="$HOME/tigeroperators"
#export OPERATOR_TYPE="community-operators" 
#export OPERATOR_NAME="NONAMEOPERATOR"
#export BRANCH_NAME="master"
#export PULL_ID=0
#export AUTH_TOKEN=""
#export PACKAGE_NAME=""
#export CHANNEL_NAME=""
#export QUAY_TOKEN=""
error(){
    divider===============================
    divider=$divider$divider
    
    header="\n %-s \n"
    format=" \%-s \n"

    width=43
    printf "$header" "ERROR"
    printf "%$width.${width}s\n" "$divider"
    printf "$format" \
    "$1"

}
createolmfun(){
olmdir="$OPERATOR_DIRECTORY/$OPERATOR_NAME/olm"
mkdir "$olmdir"
if [[ "$OPERATOR_TYPE" = "upstream-community-operators" ]] 
then
cat <<EOT >> "$olmdir"/1.operator-source.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
    name: $OPERATOR_NAME-operators
    namespace: marketplace
spec:
    type: appregistry
    endpoint: https://quay.io/cnr
    registryNamespace: "$QUAY_NAMESPACE"
EOT

cat <<EOT >> "$olmdir"/2.catalog-source-config.yaml
apiVersion: operators.coreos.com/v1
kind: CatalogSourceConfig
metadata:
    name: $OPERATOR_NAME-operators
    namespace: marketplace
spec:
    targetNamespace: olm
    packages: "$OPERATOR_NAME"
EOT

cat <<EOT >> "$olmdir"/3.operator-group.yaml
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: $OPERATOR_NAME-operatorgroup
  namespace: marketplace
#spec:
#  targetNamespaces:
#  - default
EOT

cat <<EOT >> "$olmdir"/4.operator-subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $OPERATOR_NAME-subsription
  namespace: marketplace
spec:
  channel: $CHANNEL_NAME
  name: $OPERATOR_NAME
  source: $OPERATOR_NAME-operators
  sourceNamespace: marketplace
EOT
else    
cat <<EOT >> "$olmdir"/1.operator-source.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
    name: $OPERATOR_NAME-operators
    namespace: openshift-marketplace
spec:
    type: appregistry
    endpoint: https://quay.io/cnr
    registryNamespace: "$QUAY_NAMESPACE"
EOT
fi

}
#*********************************************
# Print kubectl commands to isntall marketplace and olm required for testing "
#*********************************************
olminstallFunc(){

    if [[ "$OPERATOR_TYPE" = "upstream-community-operators" ]] 
    then
      cat <<EOG >> ./apply_olm.txt 
                INSTALL OLM
               ----------------------
               kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.11.0/crds.yaml
               kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.11.0/olm.yaml
        
               INSTALL MARKET PLACE
               ----------------------  
               (find it here "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/)

               kubectl apply -f "$OPERATOR_NAME"/operator-marketplace/deploy/upstream/

              
EOG
    echo ./apply_olm.txt
 
    fi 
}

getPackageFilenameFormat(){
     printf "Select filename for operator if its different then $OPERATOR_NAME.\n"
    selection=
        echo "
        PROGRAM MENU
        1 - Same as operator name
        2 - Different
        
    "
    while :
    do
        echo -n "Enter your selection (1/2): "
        read  selection
        echo ""
        case $selection in
            1 ) export FILE_NAME=$OPERATOR_NAME 
                break 
                ;;
            2 ) echo "Enter filename"
                read filename
                export FILE_NAME=$filename
                break
                ;;
            * ) echo "Please enter 1 or 2"
        esac
    done

}
#*********************************************
# Sets up operator  1. Creating folder , 2) cloning git 3) fetching PR 4)  and 5) switching to branch
#*********************************************
setupOperatorFunction(){
    # Begin script in case all parameters are correct
    if [[ -d "$OPERATOR_DIRECTORY" ]] 
    then
        printf "Directory %s exists.\n" "$OPERATOR_DIRECTORY"
    else
        printf "Error: Directory %s does not exists.\n" "$OPERATOR_DIRECTORY"
        read -p "Do you want to create directory $OPERATOR_DIRECTORY? " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[[Yy]]$ ]]
        then
        # do dangerous stuff
        mkdir "$OPERATOR_DIRECTORY"
        print " Directory $OPERATOR_DIRECTORY created.\n"
        else
             error "Exiting ......."
             return
        fi
    fi

    if [[ -d "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME" ]] 
    then
        printf "%s/%s ... cleaning up\n" "$OPERATOR_DIRECTORY" "$OPERATOR_NAME"
        rm -rf "$OPERATOR_DIRECTORY/$OPERATOR_NAME"
    fi
    printf "Directory %s does not exists. Creating new.\n" "$OPERATOR_NAME"
    mkdir "$OPERATOR_DIRECTORY/$OPERATOR_NAME"
    printf "Directory %s/%s created.\n" "$OPERATOR_DIRECTORY" "$OPERATOR_NAME"

    #Begin git  clone and PR's
    cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"
    git clone $source
    cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"/community-operators 
    git fetch origin pull/"$PULL_ID"/head:"$BRANCH_NAME"
    git checkout "$BRANCH_NAME"


    if [[ "$OPERATOR_TYPE" = "upstream-community-operators" ]]
    then
        printf "Cloning other required repo\n"
        cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"
        git clone https://github.com/operator-framework/operator-marketplace.git
        git clone https://github.com/operator-framework/operator-courier.git
        git clone https://github.com/operator-framework/operator-lifecycle-manager.git
        
        olminstallFunc
    else
        printf "Cloning other required repo (operator courier)\n"
        cd "$OPERATOR_DIRECTORY"/"$OPERATOR_NAME"
        git clone https://github.com/operator-framework/operator-courier.git
    fi

    printf " *----------------------------------- Done -----------------------------------*\n"
    printf "Make sure you run [[pip3 install operator-courier]].\n"
    
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
    if [[ ! -z "$FILE_NAME" ]]  &&  [[ ! -z "$OPERATOR_NAME" ]] && [[ ! -z "$OPERATOR_TYPE" ]] && [[ ! -z "$BRANCH_NAME" ]] && [[ ! -z "$PULL_ID" ]]
    then
        printf "Environment variables are set , do you wish to contiue or use new ?\n"
        printf "=======================================\n"
        printf "OPERATOR NAME : %s\n" "$OPERATOR_NAME"
        printf "OPERATOR TYPE : %s\n" "$OPERATOR_TYPE"
        printf "FILE NAME : %s\n"  "$FILE_NAME"
        printf "BRANCH NAME : %s\n" "$BRANCH_NAME"
        printf "PULL ID : %s\n" "$PULL_ID"
        printf "CHANNEL : %s\n" "$CHANNEL_NAME"
        printf "PACKAGE_NAME: %s\n" "$PACKAGE_NAME"
        printf "QUAY_NAMESPACE: %s\n" "$QUAY_NAMESPACE"
        printf "QUAY_TOKEN: %s\n" "$QUAY_TOKEN"
        printf "=======================================\n"

         while :
    do
        echo "----------------------------"
        echo -n "Continue=1  or  Setup new =2: "
        read selection
        echo ""
        case $selection in
            1 ) break
                ;;
            2 ) export FILE_NAME =""
                newoperatorType
                newoperatorName
                getPackageFilenameFormat
                printf "Enter Pull ID\n"
                read pullid
                printf "Enter Branch name (The branch name you want to create):\n"
                read brnachname
                export PULL_ID=$pullid
                export BRANCH_NAME=$brnachname
                break
                ;;
            * ) echo "Please enter 1, pr 2"
        esac
    done
    else
        export FILE_NAME=""
        newoperatorType
        newoperatorName
        getPackageFilenameFormat
        printf "Enter Pull ID\n"
        read pullid
        printf "Enter Branch name (The branch name you want to create):\n"
        read brnachname
        export PULL_ID=$pullid
        export BRANCH_NAME=$brnachname
    fi
    setupOperatorFunction
}

void(){
    return 
}
#*********************************************
# Sets up env variables
#*********************************************
testVariableSetup(){

    if [[ -z "$OPERATOR_TYPE" ]]
    then
      newoperatorType
    else
     printf "Using operator type  $OPERATOR_TYPE"  
    fi
    if [[ -z "$OPERATOR_NAME" ]]
    then
      newoperatorName
    else
       printf " Do you want to set up new or use existing operator : %s \n" "$OPERATOR_NAME"
    selection=

        echo "
        OPERATOR TYPE MENU
        1 - Use
        2 - New
    "
    while :
    do
        echo -n "Enter selection: "
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

printf "\n Enter Quay setup\n"
#if its empty and !=null
if [[ ! -z "$QUAY_TOKEN" &&  "$QUAY_TOKEN"! = "null" ]]
then
   if [[ -z "$QUAY_NAMESPACE" ]] 
   then
    echo -n "quay Namespace: "
    read quaynamespace
    export QUAY_NAMESPACE="$quaynamespace"
   fi
    printf "quay token: %s\n" "$QUAY_TOKEN"
    printf "quay token already present, if you want new token clear env variable QUAY_TOKEN and run this again.\n"
else
    if [[ -z "$QUAY_NAMESPACE" ]] 
    then
        echo -n "quay Namespace: "
        read quaynamespace
        export QUAY_NAMESPACE="$quaynamespace"
   fi
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

    if [[ -z "$QUAY_TOKEN" ]]
    then 
    printf "Error  logging  to quay %s\n" "$error"
    fi
fi

}

#*********************************************
# S Printing test commands 
#*********************************************
helpTestFunction(){ 
    local deploy_dir package_file
    useexisting=$1
    deploy_dir="${OPERATOR_DIRECTORY}/${OPERATOR_NAME}/community-operators/${OPERATOR_TYPE}/${OPERATOR_NAME}"
    package_file="${deploy_dir}/${FILE_NAME}.package.yaml"    
    if [[ "$useexisting" = 0 ]]
    then   
        testVariableSetup
        deploy_dir="${OPERATOR_DIRECTORY}/${OPERATOR_NAME}/community-operators/${OPERATOR_TYPE}/${OPERATOR_NAME}"
        if [[ -z $FILE_NAME ]]
        then
                getPackageFilenameFormat
        fi 
        package_file="${deploy_dir}/${FILE_NAME}.package.yaml"
        printf "%s/%s/community-operators/%s/%s\n" "$OPERATOR_DIRECTORY" "$OPERATOR_NAME" "$OPERATOR_TYPE" "$OPERATOR_NAME"
        if [[ ! -d "$deploy_dir" ]] 
        then
             printf "OPERATOR : %s\n" "$OPERATOR_NAME"
             error "Error: Looks like you do not have the operator setup for $OPERATOR_NAME"
             return
        fi
        
        if  [[ -e  "$package_file" ]]
        then
                printf "Checking for OLM BUNDLE... exists \n"
        else
            printf "***************************************************************************************\n"
             error " OLM  bundle does not exists for oeprator $OPERATOR_NAME , please setup operator first. \n"
             return
        fi    
    fi
    
    setupQuay
    if [[ -z "$QUAY_TOKEN" ]]
    then 
     printf "Couldn't get quay login.\n"
     QUAY_TOKEN="Couldn't get quay login"
    fi

    
    
    

    if  [[ ! -e  "$deploy_dir/$FILE_NAME.package.yaml" ]]
    then
        export PACKAGE_NAME="UNKNOWN"
        export PACKAGE_VERSION="0.0.0"
        export CHANNEL_NAME="UNKNOWN"
        error "Check if you have entered valid pull id "$PULL_ID""
        error " No such file or directory "${package_file}""
        return
    else
        export PACKAGE_NAME="$(cat "${package_file}" | grep packageName | cut -f 2 -d' ' | awk '{print $1}')"
        echo " PACKAGE_VERSION=$(cat "${package_file}" | grep currentCSV | cut -d'.' -f2- | cut -d'v' -f2- | awk '{print $1}' )"
        export PACKAGE_VERSION="$(cat "${package_file}" | grep currentCSV | cut -d'.' -f2- | cut -d'v' -f2- | awk '{print $1}' )"
        echo "CHANNEL_NAME=$(cat "${package_file}" | grep  name | cut -f 2 -d':' | awk '{print $1}')"
        export CHANNEL_NAME="$(cat "${package_file}" | grep  name | cut -f 2 -d':' | awk '{print $1}')"
    fi
    summary
    olminstallFunc
        
}

#*********************************************
# Slapsh screen shown at the start
#*********************************************
startupMenuFunction(){
    printf "Select operator setup option or test command.\n"
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
    createolmfun
    helpTestFunction 1
}


summary(){
    divider===============================
    divider=$divider$divider$divider$divider
    local deploy_dir="${OPERATOR_DIRECTORY}/${OPERATOR_NAME}/community-operators/${OPERATOR_TYPE}/${OPERATOR_NAME}"

    header="\n%-20s %20s %20s %20s\n"
    format="\n%-20s %20s %20s %20s\n"
    width=100
    printf "$header" "OPERATOR NAME" "OPERATOR TYPE" "PULL ID" "QUAY TOKEN"
    printf "%$width.${width}s\n" "$divider"
    printf "$format" \
    "$OPERATOR_NAME" "$OPERATOR_TYPE" "$PULL_ID" "$QUAY_TOKEN"  
     
    format2="\n%-20s \n"
    header2="\n%-20s \n"
    printf "$header2" "LINTING"
    printf "%$width.${width}s\n" "$divider"
    printf "$format2" \
    "operator-courier verify --ui_validate_io "$deploy_dir""
    

    printf "$header2" "QUAY PUSHING"
    printf "%$width.${width}s\n" "$divider"
    printf "$format2" \
    "operator-courier push \""${deploy_dir}"\" \""${QUAY_NAMESPACE}"\" \""${PACKAGE_NAME}"\" \""${PACKAGE_VERSION}"\" "${QUAY_TOKEN}""
    
     printf "$format2"\ 
    "scripts/ci/test-operator '${OPERATOR_TYPE}/${OPERATOR_NAME}' '${PACKAGE_VERSION}' 'upstream'"

    printf "$header2" "Folder"
    printf "%$width.${width}s\n" "$divider"
    printf "$format2" \
    "$OPERATOR_DIRECTORY/$OPERATOR_NAME/$OPERATOR_TYPE"
    printf  "\n"

    cat <<EOF >> ./apply.txt

        operator-courier push "${deploy_dir}" "${QUAY_NAMESPACE}" "${PACKAGE_NAME}" "${PACKAGE_VERSION}" "${QUAY_TOKEN}"

        scripts/ci/test-operator '${OPERATOR_TYPE}/${OPERATOR_NAME}' '${PACKAGE_VERSION}' 'upstream'
        
        operator-courier verify --ui_validate_io "$deploy_dir"

EOF
    
}

startupMenuFunction
