#!/bin/bash

AWSBIN=aws
STACKNAMEVPC="vpcgrp3"
STACKNAMESECGRP="securitygroup3"
STACKNAMEEC2="instancegrp3"
STACKNAMERDS="rdsgrp3"
TPL=""
INSTANCE_TYPE=""
KEYNAME="projet1grp3key"
PEMKEYNAME=$KEYNAME".pem"
REGION="eu-west-2"
REGIONAZ=$REGION"a"
DBNAME="DB"
DBUSER="groupe3"
DBPWD=$(cat sec/dbkey.txt)
ANSIBKEY=$(cat sec/ansibkey.txt)
DEVOPSKEY=$(cat sec/devopsuserkey.txt)
JENKINSKEY=$(cat sec/jenkinskey.txt)
ROOTKEY=$(cat sec/root.txt)
ENV=""
DBSIZE=5
# EC2PRIVIP=""
# PORTAPP=""

#RAZ trace.log local
echo "" > trace.log

read -p "Saisir un nom de region (London=eu-west-2 Frankfort=eu-central-1) Defaut=> [eu-west-2]: " REGION
REGION=${REGION:-eu-west-2}
echo $REGION

# TEST si la cle existe
if ! [ -f $PEMKEYNAME ]; then
  $AWSBIN ec2 create-key-pair --key-name $KEYNAME --query "KeyMaterial" --output text > $PEMKEYNAME
fi

################### START FONCTION##############
##
#PARAM="ParameterKey=KeyName,ParameterValue=$KEYNAME"
#$TPL=""
#TEXTDESC="VPCID"
#QUERY="VpcId"
#FXCREATE_STACK "$?" "$REGION" "$TPL" "$STACKNAMEVPC" "$PARAM" "$QUERY" "$TEXTDESC"
#FXCREATE_STACK "$1" "$2"      "$3"   "$4"            "$5"     "$6"         "7"       <<===correspondance
FXCREATE_STACK () {
    if [ $1 == 254 ]; then
        #Creation du stack + wait creation + infos stack
        RETCREAT1=$($AWSBIN cloudformation create-stack --template-body file://aws_cloudform/$3.yaml --stack-name $4 --parameters $5)
        if [[ "$4" = "$STACKNAMEVPC"  ||  "$4" = "$STACKNAMESECGRP"  ]]; then
            RETCREAT2=$($AWSBIN cloudformation wait stack-create-complete --stack-name $4)
            RETCREAT3=$($AWSBIN cloudformation describe-stacks --stack-name $4)
        fi
            #LOG des commandes
            echo "==>RETOUR CREATE STACK $4<==" 1>>trace.log 2>&1
            echo $RETCREAT1 1>>trace.log 2>&1
            echo "==>RETOUR CREATE WAIT STACK $4<==" 1>>trace.log 2>&1
            echo $RETCREAT2 1>>trace.log 2>&1
            echo "==>RETOUR describe-stacks STACK $4<==" 1>>trace.log 2>&1
            echo $RETCREAT3 1>>trace.log 2>&1

            #RECUPERATION DU VPC ID
            FXOUTPUTRET=$($AWSBIN cloudformation --region $2 describe-stacks --stack-name $4 --query "$6" --output text)
            FXOUTPUTRET=$(echo $FXOUTPUTRET | awk 1 ORS='')
            echo "$7==> $FXOUTPUTRET  " 1>>trace.log 2>&1
            echo $FXOUTPUTRET
            echo "------END CREATE STACK $4-------" 1>>trace.log 2>&1
    else
        #RECUPERATION DU VPC ID
        FXOUTPUTRET=$($AWSBIN cloudformation --region $2 describe-stacks --stack-name $4 --query "$6" --output text)
        FXOUTPUTRET=$(echo $FXOUTPUTRET | awk 1 ORS='')
        echo "$7==> $FXOUTPUTRET  " 1>>trace.log 2>&1
        echo $FXOUTPUTRET
    fi
}

#Fonction qui permet de récupérer la describe list suivant le service Type et la commande de description
#FXDESC_FILTER1=FXDESC_FILTER ""
#SVCTYPE="rds"
#DESCRIBECMD="describe-db-instances"
#QUERY="DBInstances[*].[ [[TagList[?Key==\`aws:cloudformation:stack-name\`].Value]],[Endpoint.Address] ]"
#FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1"
#FXAWS_DESCRIBE $1          $2            $3        $4       $5                 <<===correspondance
#INIT VAR RECUPERATION des 2 entrées du tableau dans la fonction FXAWS_DESCRIBE
T1FXAWS_DESCRETURN=""
T2FXAWS_DESCRETURN=""
FXAWS_DESCRIBE () {
    declare -a TAB1=()

    #Recupere la describe list
    RDSLIST1=$($AWSBIN $1 $2 --region $3 --output text --query "$4")
    echo ""
    SAVEIFS=$IFS   # Save current IFS
    IFS=$'\n'      # Change IFS to new line
    RDSLIST1=($RDSLIST1) # split to array $names
    IFS=$SAVEIFS   # Restore IFS
    declare -i k=0
    for (( i=0; i<${#RDSLIST1[@]}; i++ ))
    do
        ((k++))
        if [[ $(grep "$5" <<<${RDSLIST1[$i]} ) ]]; then
            local TAB1[0]=${RDSLIST1[$i]}
            ((i++))
            j=$i
            k=$((k+1))
            local TAB1[1]=${RDSLIST1[((j++))]}
            continue
        fi
    done
    echo "T1FXAWS_DESCRETURN=\"${TAB1[0]}\"; T2FXAWS_DESCRETURN=\"${TAB1[1]}\""
}
##
################### END FONCTION##############

############ START CREATION VPC et GROUPE DE SECURITE#################
##
#TEST si le VPC existe sinon le créé
#Creation du VPC
echo "RETOUR VPC INFOS $STACKNAMEVPC si existe sinon creation:"
RETVPCINFOS=$($AWSBIN cloudformation --region $REGION describe-stacks --stack-name $STACKNAMEVPC )
RETCODE=$?
PARAM="ParameterKey=KeyName,ParameterValue=$KEYNAME"
TEXTDESC="VPCID"
TPL=$STACKNAMEVPC
QUERY="Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue"
RESULTVPCID=$(FXCREATE_STACK "$RETCODE" "$REGION" "$TPL" "$STACKNAMEVPC" "$PARAM" "$QUERY" "$TEXTDESC")
echo "La stack $STACKNAMEVPC : $RESULTVPCID"
echo ""

#TEST si le groupe de securité existe sinon creation du groupe de securité
#check VPCID attente de la creation
sleep 5s
RETVPCINFOS=$($AWSBIN cloudformation --region $REGION describe-stacks --stack-name $STACKNAMEVPC --output text --query "DBInstances[*].[ [[TagList[?Key==\`aws:cloudformation:stack-name\`].Value]] ] ")
#Creation du GRoupe de securité
echo "RETOUR groupe de securité  INFOS $STACKNAMESECGRP si existe sinon creation:"
RETSECGRPINFOS=$($AWSBIN cloudformation --region $REGION describe-stacks --stack-name $STACKNAMESECGRP )
RETCODE=$?
PARAM="ParameterKey=VpcId,ParameterValue=$RESULTVPCID"
QUERY="Stacks[0].Outputs[?OutputKey=='GroupeSec1'].OutputValue"
TEXTDESC="GRPSECID"
TPL=$STACKNAMESECGRP
RESULTGRPSECID=$(FXCREATE_STACK "$RETCODE" "$REGION" "$TPL" "$STACKNAMESECGRP" "$PARAM" "$QUERY" "$TEXTDESC")
echo "La stack $STACKNAMESECGRP : $RESULTGRPSECID"
echo ""
##
############ END CREATION VPC et GROUPE DE SECURITE#################


#################### START RDS ###############
##
#RECUPERE LA LISTE DES RDS DISPONIBLE ET TEST SI EXISTE SINON CREATION
echo "LISTE des RDS disponible: "
echo " (Temps de creation rds 7 min relancer le script dans 8min pour avoir le dns de chaque rds.)"
#declare -a RETRDSLISTINFOS
RETRDSLISTINFOS=$($AWSBIN rds describe-db-instances --region $REGION --output text --query "DBInstances[*].[ [[TagList[?Key==\`aws:cloudformation:stack-name\`].Value]] ] ")
echo "$RETRDSLISTINFOS"

#Mise en tableau de la liste des stack rds sans \n et ajout des ec2
TABSTACKLST=()
TABSTACKLST1=($RETRDSLISTINFOS)
#TABSTACKLST=("${TABSTACKLST1[@]}")
for value in "${TABSTACKLST1[@]}"
do
    TABSTACKLST[${#TABSTACKLST[@]}]=$(echo $value | awk 1 ORS='')
done
TABSTACKLST[${#TABSTACKLST[@]}]="jenkins"
TABSTACKLST[${#TABSTACKLST[@]}]="nexus"
TABSTACKLST[${#TABSTACKLST[@]}]="$STACKNAMEVPC"
TABSTACKLST[${#TABSTACKLST[@]}]="$STACKNAMESECGRP"
echo ""


#TEST si la stack RDSDEV existe sinon creation de la BDD Mysql
ENV="DEV"
##==>ELEMENTS de configuration pour le RDS de DEV/QUA/PROD
STACKNAMEENV=$STACKNAMERDS$ENV
FXDESC_FILTER1=$STACKNAMEENV
#Filtre sur DBINSTANCE et cherche 2 éléments
QUERY="DBInstances[*].[ [[TagList[?Key==\`aws:cloudformation:stack-name\`].Value]],[Endpoint.Address] ]"
SVCTYPE="rds"
DESCRIBECMD="describe-db-instances"
##<==

#Retourne le rds stackname et son dns de la fonction avec eval et echo
eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
#echo $T1FXAWS_DESCRETURN
#echo $T2FXAWS_DESCRETURN
##Vérification que $T1STACKNAME est non vide
#    -z : retourne vrai si la taille de la chaîne vaut zéro.
#    -n : retourne vrai si la taille de la chaîne n’est pas zéro.
if ! [ -n "$T1FXAWS_DESCRETURN"  ]; then
    echo "Creation de la RDS de DEV"
    #Creation du RDS BDD DEV
    DBNAMEENV=$DBNAME$ENV
    RETRDSINFOS=$($AWSBIN cloudformation --region $REGION describe-stacks --stack-name $STACKNAMEENV )
    RETCODE=$?
    PARAM="ParameterKey=subnet1CIDR,ParameterValue=10.80.210.0/24 ParameterKey=subnet2CIDR,ParameterValue=10.80.211.0/24 ParameterKey=AllocatedStorage,ParameterValue=$DBSIZE ParameterKey=DBName,ParameterValue=$DBNAMEENV ParameterKey=MUser,ParameterValue=$DBUSER ParameterKey=MPass,ParameterValue=$DBPWD ParameterKey=VpcId,ParameterValue=$RESULTVPCID ParameterKey=Env,ParameterValue=$ENV ParameterKey=SecurityGroupId,ParameterValue=$RESULTGRPSECID ParameterKey=PrimaryAZ,ParameterValue=$REGIONAZ"
    #PARAM="ParameterKey=AllocatedStorage,ParameterValue=$DBSIZE ParameterKey=DBName,ParameterValue=$DBNAMEENV ParameterKey=MUser,ParameterValue=$DBUSER ParameterKey=MPass,ParameterValue=$DBPWD ParameterKey=VpcId,ParameterValue=$RESULTVPCID ParameterKey=Env,ParameterValue=$ENV ParameterKey=SecurityGroupId,ParameterValue=$RESULTGRPSECID ParameterKey=PrimaryAZ,ParameterValue=$REGIONAZ"
    QUERY="DBInstances[*].[ [DBInstanceIdentifier],[Endpoint[0].[Address] ] ]"
    TEXTDESC="NULL"
    TPL=$STACKNAMERDS
    RESULTRDSDEV=$(FXCREATE_STACK "$RETCODE" "$REGION" "$TPL" "$STACKNAMEENV" "$PARAM" "$QUERY" "$TEXTDESC")
    echo "La stack $STACKNAMEENV est en cours de creation: $RESULTRDSDEV"
else
    eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
    echo "LE DNS du stack $T1FXAWS_DESCRETURN est : $T2FXAWS_DESCRETURN"
fi

#TEST si la stack RDSDQUA existe sinon creation de la BDD Mysql
ENV="QUA"
STACKNAMEENV=$STACKNAMERDS$ENV
FXDESC_FILTER1=$STACKNAMEENV
#Filtre sur DBINSTANCE et cherche 2 éléments
QUERY="DBInstances[*].[ [[TagList[?Key==\`aws:cloudformation:stack-name\`].Value]],[Endpoint.Address] ]"
SVCTYPE="rds"
DESCRIBECMD="describe-db-instances"
eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
if ! [ -n "$T1FXAWS_DESCRETURN"  ]; then
    #Creation du RDS BDD QUA
    DBNAMEENV=$DBNAME$ENV
    RETRDSINFOS=$($AWSBIN cloudformation --region $REGION describe-stacks --stack-name $STACKNAMEENV )
    RETCODE=$?
    PARAM="ParameterKey=subnet1CIDR,ParameterValue=10.80.220.0/24 ParameterKey=subnet2CIDR,ParameterValue=10.80.221.0/24 ParameterKey=AllocatedStorage,ParameterValue=$DBSIZE ParameterKey=DBName,ParameterValue=$DBNAMEENV ParameterKey=MUser,ParameterValue=$DBUSER ParameterKey=MPass,ParameterValue=$DBPWD ParameterKey=VpcId,ParameterValue=$RESULTVPCID ParameterKey=Env,ParameterValue=$ENV ParameterKey=SecurityGroupId,ParameterValue=$RESULTGRPSECID ParameterKey=PrimaryAZ,ParameterValue=$REGIONAZ"
    #PARAM="ParameterKey=AllocatedStorage,ParameterValue=$DBSIZE ParameterKey=DBName,ParameterValue=$DBNAMEENV ParameterKey=MUser,ParameterValue=$DBUSER ParameterKey=MPass,ParameterValue=$DBPWD ParameterKey=VpcId,ParameterValue=$RESULTVPCID ParameterKey=Env,ParameterValue=$ENV ParameterKey=SecurityGroupId,ParameterValue=$RESULTGRPSECID ParameterKey=PrimaryAZ,ParameterValue=$REGIONAZ"
    QUERY="DBInstances[*].[ [DBInstanceIdentifier],[Endpoint[0].[Address] ] ]"
    TEXTDESC="NULL"
    TPL=$STACKNAMERDS
    RESULTRDSDEV=$(FXCREATE_STACK "$RETCODE" "$REGION" "$TPL" "$STACKNAMEENV" "$PARAM" "$QUERY" "$TEXTDESC")
    echo "La stack $STACKNAMEENV est en cours de creation : $RESULTRDSQUA"
else
    eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
    echo "LE DNS du stack $T1FXAWS_DESCRETURN est : $T2FXAWS_DESCRETURN"
fi


#TEST si la stack RDSDPROD existe sinon creation de la BDD Mysql
ENV="PROD"
STACKNAMEENV=$STACKNAMERDS$ENV
FXDESC_FILTER1=$STACKNAMEENV
eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
#if ! [ -n "$T1FXAWS_DESCRETURN"  ]; then
if ! [ -n "$T1FXAWS_DESCRETURN"  ]; then
    #Creation du RDS BDD PROD
    RETRDSINFOS=$($AWSBIN cloudformation --region $REGION describe-stacks --stack-name $STACKNAMEENV )
    RETCODE=$?
    DBNAMEENV=$DBNAME$ENV
    PARAM="ParameterKey=subnet1CIDR,ParameterValue=10.80.230.0/24 ParameterKey=subnet2CIDR,ParameterValue=10.80.231.0/24 ParameterKey=AllocatedStorage,ParameterValue=$DBSIZE ParameterKey=DBName,ParameterValue=$DBNAMEENV ParameterKey=MUser,ParameterValue=$DBUSER ParameterKey=MPass,ParameterValue=$DBPWD ParameterKey=VpcId,ParameterValue=$RESULTVPCID ParameterKey=Env,ParameterValue=$ENV ParameterKey=SecurityGroupId,ParameterValue=$RESULTGRPSECID ParameterKey=PrimaryAZ,ParameterValue=$REGIONAZ"
    #PARAM="ParameterKey=AllocatedStorage,ParameterValue=$DBSIZE ParameterKey=DBName,ParameterValue=$DBNAMEENV ParameterKey=MUser,ParameterValue=$DBUSER ParameterKey=MPass,ParameterValue=$DBPWD ParameterKey=VpcId,ParameterValue=$RESULTVPCID ParameterKey=Env,ParameterValue=$ENV ParameterKey=SecurityGroupId,ParameterValue=$RESULTGRPSECID ParameterKey=PrimaryAZ,ParameterValue=$REGIONAZ"
    QUERY="DBInstances[*].[ [DBInstanceIdentifier],[Endpoint[0].[Address] ] ]"
    TEXTDESC="NULL"
    TPL=$STACKNAMERDS
    RESULTRDSPROD=$(FXCREATE_STACK "$RETCODE" "$REGION" "$TPL" "$STACKNAMEENV" "$PARAM" "$QUERY" "$TEXTDESC")
    echo "La stack $STACKNAMEENV est en cours de creation: $RESULTRDSPROD"
else
    eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
    echo "LE DNS du stack $T1FXAWS_DESCRETURN est : $T2FXAWS_DESCRETURN"
fi
##
#################### END RDS ###############
echo ""

# echo "Liste des Instances EC2 disponible:"
# RETEC2INFOS=$($AWSBIN ec2 describe-instances --region $REGION )
# echo $RETEC2INFOS

# echo ""
# echo "------START CREATE STACK-------" 1>>trace.log 2>&1
# read -p "Saisir jenkins ou nexus pour les actions STACK suivante CREATE/UPDATE/DELETE: " n1
# ${TABSTACKLST[@]}
# select var in "${CHOIX[@]}"; do
#     case $var in
#         "CREATE")

echo ""
# CHOIX SELECT Dynamique en fonction du tableau la liste des stack
###
echo "Saisir le n° de STACK pour les actions CREATE/UPDATE/DELETE:"
oldIFS=$IFS
IFS=$'\n'
choices=( ${TABSTACKLST[@]} )
IFS=$oldIFS
PS3="Please enter your choice: "
select answer in "${choices[@]}"; do
  for item in "${choices[@]}"; do
    if [[ $item == $answer ]]; then
      break 2
    fi
  done
done
echo ""
n1=$answer
###

OLDIFS=$IFS
IFS="|"
#jenkins
if [ "$n1" = "jenkins" ]; then
    IFS=$OLDIFS
    echo "Choix de la Stack $n1 effectué."
    TYPEINSTALL=$n1
    EC2PRIVIP="10.80.140.10"
    PORTAPP="8080"
    TYPEINSTANCE="t2.micro"
    TPL="$STACKNAMEEC2"
    STACKNAMEEC2="jenkins"
    CMDSCRIPT="$n1"
#    CMDSCRIPT="sudo wget -O /tmp/install_jenkins.sh https://raw.githubusercontent.com/KevinGit31/depot_projet_1_file_rouge/dev/infra/install_jenkins.sh && chmod +x /tmp/install_jenkins.sh && sudo /bin/bash /tmp/install_jenkins.sh"
elif [ "$n1" = "nexus" ]; then
    IFS=$OLDIFS
    echo "Choix de la Stack $n1 effectué."
    TYPEINSTALL=$n1
    EC2PRIVIP="10.80.140.11"
    PORTAPP="8081"
    TYPEINSTANCE="t2.small"
    TPL="$STACKNAMEEC2"
    STACKNAMEEC2="nexus"
    CMDSCRIPT="$n1"
#    CMDSCRIPT="(sudo wget -O /tmp/install_nexus.sh https://raw.githubusercontent.com/KevinGit31/depot_projet_1_file_rouge/dev/infra/install_nexus.sh && chmod +x /tmp/install_nexus.sh && sudo /bin/bash /tmp/install_nexus.sh)
elif [ -n "$n1  | grep -E \"${TABSTACKLST[*]}\"" ]; then
    IFS=$OLDIFS
    echo "STACK $n1"
else
    echo "Mauvaise saisi."
    IFS=$OLDIFS
    exit
fi

echo "Choisir une action de stack 1,2,3 ou 4."
echo ""
CHOIX=("CREATE" "UPDATE" "DELETE" "EXIT")
echo ""

######### START CREATION DE LA STACK INSTANCE  jenkins et nexus + UPDATE ET DELETE DE LA STACK #########
##

select var in "${CHOIX[@]}"; do
    case $var in
        "CREATE")
#            #RECUPERATION DU VPC ID pour y attacher le groupe de se securité
            VPCID=$($AWSBIN cloudformation --region $REGION describe-stacks --stack-name $STACKNAMEVPC --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" --output text)

            # #Recuperation de la liste de groupe de secutité
            FXDESC_FILTER1=$STACKNAMESECGRP
            #Filtre sur DBINSTANCE et cherche 2 éléments
            QUERY="SecurityGroups[*].[ [GroupName],[GroupId] ]"
            SVCTYPE="ec2"
            DESCRIBECMD="describe-security-groups"
            ##<==

            #Retour du tableau en index 0 SECGRPLISTID et index 1 SECGRPID
            eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
            SECGRPLISTID=$T1FXAWS_DESCRETURN
            SECGRPID=$T2FXAWS_DESCRETURN
            #Recuperation de la liste de subnet PRIVATE ADM
            FXDESC_FILTER1="PrivateSubnetADM"
            #Filtre sur DBINSTANCE et cherche 2 éléments
            QUERY="Subnets[*].[ [Tags[?Key==\`aws:cloudformation:logical-id\`].Value],[SubnetId] ]"
            SVCTYPE="ec2"
            DESCRIBECMD="describe-subnets"
            ##<==

            #Retour du tableau SUBNETLISTIDPUB SUBNETLISTIDPUB et SUBNETLISTIDPRIV
            eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
            SUBNETLISTIDPRIVID=$T2FXAWS_DESCRETURN
            SUBNETLISTIDPRIV=$T1FXAWS_DESCRETURN
            #Recuperation de la liste de subnet public ADM
            FXDESC_FILTER1="PublicSubnetADM"
            #Filtre sur DBINSTANCE et cherche 2 éléments
            QUERY="Subnets[*].[ [Tags[?Key==\`aws:cloudformation:logical-id\`].Value],[SubnetId] ]"
            SVCTYPE="ec2"
            DESCRIBECMD="describe-subnets"
            ##<==

            #Retour du tableau SUBNETLISTIDPUB SUBNETLISTIDPUB et SUBNETLISTIDPRIV
            eval $(FXAWS_DESCRIBE "$SVCTYPE" "$DESCRIBECMD" "$REGION" "$QUERY" "$FXDESC_FILTER1")
            SUBNETLISTIDPUBID=$T2FXAWS_DESCRETURN
            SUBNETLISTIDPUB=$T1FXAWS_DESCRETURN
            #Creation de l'instance
            #Retour instance Infos
            #RETINSTANCEINFOS=$($AWSBIN ec2 --region $REGION --output text )
            RETCODE="254"
#            PARAM="ParameterKey=KeyName,ParameterValue=$KEYNAME ParameterKey=SubnetIdPub,ParameterValue=\"$SUBNETLISTIDPUBID\" ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0 ParameterKey=SubnetIdPriv,ParameterValue=$SUBNETLISTIDPRIVID ParameterKey=PrivateIP,ParameterValue=$EC2PRIVIP ParameterKey=TypeName,ParameterValue=$TYPEINSTALL ParameterKey=IngressPort,ParameterValue=$PORTAPP ParameterKey=Urlscript,ParameterValue=$CMDSCRIPT ParameterKey=SecurityGroupNameList,ParameterValue=$SECGRPLISTID ParameterKey=SecurityGroupId,ParameterValue=$SECGRPID ParameterKey=InstanceType,ParameterValue=$TYPEINSTANCE"
            PARAM="ParameterKey=KeyName,ParameterValue=$KEYNAME ParameterKey=Environnement,ParameterValue=dev ParameterKey=RootKey,ParameterValue=$ROOTKEY ParameterKey=JenkinsKey,ParameterValue=$JENKINSKEY ParameterKey=DevOpsKey,ParameterValue=$DEVOPSKEY ParameterKey=AnsibleKey,ParameterValue=$ANSIBKEY ParameterKey=SubnetIdPub,ParameterValue=$SUBNETLISTIDPUBID ParameterKey=SubnetIdPriv,ParameterValue=$SUBNETLISTIDPRIVID ParameterKey=VpcId,ParameterValue=$VPCID ParameterKey=PrivateIP,ParameterValue=$EC2PRIVIP ParameterKey=TypeName,ParameterValue=$TYPEINSTALL ParameterKey=IngressPort,ParameterValue=$PORTAPP ParameterKey=SecurityGroupNameList,ParameterValue=$SECGRPID ParameterKey=Urlscript,ParameterValue=$CMDSCRIPT ParameterKey=SecurityGroupId,ParameterValue=$SECGRPID ParameterKey=InstanceType,ParameterValue=$TYPEINSTANCE"
            #echo $PARAM
            QUERY="Stacks[0].Outputs[?OutputKey=='GroupeSec1'].OutputValue"
            TEXTDESC="NULL"

            RESULTEC2ID=$(FXCREATE_STACK "$RETCODE" "$REGION" "$TPL" "$STACKNAMEEC2" "$PARAM" "$QUERY" "$TEXTDESC")
            echo "Creation de la STACK $STACKNAMEEC2 : "
            sleep 10s
            STACKLISTNAME=$($AWSBIN cloudformation describe-stack-resources --stack-name $STACKNAMEEC2 --output text --query 'StackResources[*].[ [ResourceStatus] ]')
            echo $STACKLISTNAME
            ;;
        "UPDATE")
            echo "------START UPDATE STACK-------" 1>>trace.log 2>&1
            #Recuperation de la liste des stack
            STACKLISTNAME=$($AWSBIN cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --query 'StackSummaries[*].[ [StackName] ]')
            echo "Liste des stack CREATE_COMPLETE pour UPDATE: $STACKLISTNAME"
            read -p "Saisir une stack de la liste: " UPSTACKNAME
            #Update de la stack
            RETUPT1=$($AWSBIN cloudformation update-stack --template-body file://aws_cloudform/$UPSTACKNAME.yaml --stack-name $UPSTACKNAME)
            RETUPT2=$($AWSBIN cloudformation cloudformation wait stack-update-complete --stack-name $UPSTACKNAME)
            RETUPT3=$($AWSBIN cloudformation describe-stacks --stack-name $UPSTACKNAME)
            echo "==>RETOUR UPDATE STACK $UPSTACKNAME<==" 1>>trace.log 2>&1
            echo $RETUPT1 1>>trace.log 2>&1
            echo "==>RETOUR UPDATE WAIT STACK $UPSTACKNAME<==" 1>>trace.log 2>&1
            echo $RETUPT2 1>>trace.log 2>&1
            echo "==>RETOUR UPDATE WAIT STACK $UPSTACKNAME<==" 1>>trace.log 2>&1
            echo $RETUPT3 1>>trace.log 2>&1
            echo "------END UPDATE STACK $UPSTACKNAME-------" 1>>trace.log 2>&1
            ;;
        "DELETE")
            echo "------START DELETE STACK-------" 1>>trace.log 2>&1
            #Recuperation de la liste des stack
            STACKLISTNAME=$($AWSBIN cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --query 'StackSummaries[*].[ [StackName] ]')
            # TABSTACKLST2=()
            # TABSTACKLST2=$($AWSBIN cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --query 'StackSummaries[*].[ [StackName] ]')
            # sleep 3s
            # echo "Liste des stack avec le status CREATE_COMPLETE :"
            # echo ${TABSTACKLST2[0]}
            echo "Liste des stack avec le status CREATE_COMPLETE :"
            echo $STACKLISTNAME
            read -p "Saisir une stack à supprimer de la liste: " DELSTACKNAME
            RETDEL1=$($AWSBIN cloudformation delete-stack --stack-name $DELSTACKNAME)
            STACKLISTNAME=$($AWSBIN cloudformation list-stacks --stack-status-filter DELETE_IN_PROGRESS --output text --query 'StackSummaries[*].[ [StackName] ]')
            echo "Liste des stack avec le status DELETE_IN_PROGRESS :"
            echo $STACKLISTNAME
            echo $RETDEL1 1>>trace.log 2>&1
            echo "------END DELETE STACK $DELSTACKNAME-------" 1>>trace.log 2>&1
            ;;
        "INFOS")
             STACKLISTNAME=$($AWSBIN cloudformation list-stacks --output text --query 'StackSummaries[*].[ [StackName] ]')
             echo "$STACKLISTNAME"
             ;;
        "EXIT")
            echo "EXIT" 1>>trace.log 2>&1
            exit
            ;;
        *)
            echo "CHOIX NON VALIDE"
            ;;
    esac
done
##
######### END CREATION DE LA STACK INSTANCE  jenkins et nexus + UPDATE ET DELETE DE LA STACK #########