node {
// Chargement des variables d'environnements password + id aws
   load "$JENKINS_HOME/.envvars/stacktest-staging.groovy"
}
pipeline {
    environment {
// initailisation de variable d'environnement supplémentaires
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "10.80.140.11:8081"
        NEXUS_REPOSITORY = "APP"
        NEXUS_CREDENTIAL_ID = "nexus"
        NEXUS_ARTIFACT_ID = "qcm"
        NEXUS_GROUP_ID = "1"
        ROOTKEY_ENV = "NONE"
        JENKINS_KEY = "NONE"
        ANSIBLE_KEY = "NONE"
        ENVIRONNEMENT = "${env.JOB_BASE_NAME}"
        TYPENAME_ENV = "qcm${env.JOB_BASE_NAME}"
        REGION_ENV = "${REGION}"
        BRANCHS_ENV = "${env.JOB_BASE_NAME}"
        MAJBRANCHS_ENV = "${BRANCHS_ENV.toUpperCase()}"
        //VARIABLE A MODIFIER SUIVANT L4ENVIRONNEMENT
        //PRIVIP_ENV = "10.80.110.10"
        CREDENTIALS_NEXUS = credentials('nexus')
        DBNAME_ENV = "dbquizz"
        CREDENTIALS_DB = credentials('dbqcm')
        NEXUS_STACK_NAME = "nexus"


    }
//
agent any
// init IP suivant environnement
    stages {
        stage('ipvarenv') {
            steps {
                //sh 'rm -rf depot_projet_1_file_rouge'
                script {
                    if ( "${BRANCHS_ENV}" == 'dev') {
                        PRIVIP_ENV = "10.80.110.10"
                    }
                    if ( "${BRANCHS_ENV}" == 'qua') {
                        PRIVIP_ENV = "10.80.120.20"
                    }
                    if ( "${BRANCHS_ENV}" == 'prod') {
                        PRIVIP_ENV = "10.80.130.30"
                    }
                }
            }
        }
// CLONE DU DEPOT
//    stages {
        stage('clone source') {
            steps {
                sh 'rm -rf depot_projet_1_file_rouge'
                script {
                    if ( "${BRANCHS_ENV}" == 'prod') {
                        git branch: 'prod', url: 'https://github.com/KevinGit31/depot_projet_1_file_rouge.git'
                    } else {
                        git branch: "${BRANCHS_ENV}", url: 'https://github.com/KevinGit31/depot_projet_1_file_rouge.git'
                    }
                }
            }
        }
// MISE EN ARCHIVE de L'APP
        stage("Build") {
            steps {
                script {
                    sh 'tar cvfz qcm.tar.gz quizz/'
                }
            }
        }
// MISE EN DEPOT ET VERSION de L'ARCHIVE sur le NEXUS
        stage('push nexus') {
            steps{
                nexusArtifactUploader artifacts: [
                    [
                        artifactId: "${NEXUS_ARTIFACT_ID}",
                        classifier: '',
                        file: "qcm.tar.gz",
                        type: 'tar.gz'
                        ]
                    ],
                    credentialsId: "${NEXUS_CREDENTIAL_ID}",
                    groupId: "${NEXUS_GROUP_ID}",
                    nexusUrl: "${NEXUS_URL}",
                    nexusVersion: "${NEXUS_VERSION}",
                    protocol: "${NEXUS_PROTOCOL}",
                    repository: "${NEXUS_REPOSITORY}",
                    version: "1.0-${BUILD_NUMBER}"
            }
        }
// TEST SI L'ARCHIVE VERSIONNé EST DISPO SUR LE NEXUS
        stage('testnexuscible'){
            steps {
                sh 'sleep 2s'
                sh "curl http://${NEXUS_URL}/repository/${NEXUS_REPOSITORY}/${NEXUS_ARTIFACT_ID}/1.0-${BUILD_NUMBER}/${NEXUS_ARTIFACT_ID}-1.0-${BUILD_NUMBER}.tar.gz"
            }
        }
// RECUPERATION DU DNS PUBLIC RDS BDD de TEST + BDD + NEXUS
        stage('getdnsrdsdb'){
            steps {
                script {
                    env.DNSDBTEST_ENV = "${sh(script:'chmod +x infra/checkrds.sh && ./infra/checkrds.sh ${REGION_ENV} \"test\"', returnStdout: true).trim()}"
                    env.DNSDB_ENV = "${sh(script:'chmod +x infra/checkrds.sh && ./infra/checkrds.sh ${REGION_ENV} ${ENVIRONNEMENT}', returnStdout: true).trim()}"
                    env.DNSPUBEC2NEXUS_ENV = "${sh(script:'chmod +x infra/getdnspubEC2id.sh && ./infra/getdnspubEC2id.sh nexus ${REGION_ENV}', returnStdout: true).trim()}"
                }
            }
        }
// PREPARATION DES VARIABLES POUR ANSIBLE
        stage('ansibleprep'){
            steps {
                script {

                    if ( "${BRANCHS_ENV}" == 'dev') {
                        env.SUBNETIDPUBADM_ENV = "${SUBIDPUBDEV}"
                        env.SUBNETIDPRIVADM_ENV = "${SUBIDPRIVDEV}"
                    } else if ( "${BRANCHS_ENV}" == 'qua'){
                        env.SUBNETIDPUBADM_ENV = "${SUBIDPUBQUA}"
                        env.SUBNETIDPRIVADM_ENV = "${SUBIDPRIVQUA}"
                    } else if ( "${BRANCHS_ENV}" == 'prod'){
                        env.SUBNETIDPUBADM_ENV = "${SUBIDPUBPROD}"
                        env.SUBNETIDPRIVADM_ENV = "${SUBIDPRIVPROD}"
                    }
                    env.INGRPORT = "5000"
                    sh 'yes | cp -rf infra/aws_cloudform/instancegrp3.yaml infra/ansible/roles/common/tasks/instancegrp3.yaml'
                    writeFile file: "/var/lib/jenkins/workspace/dev/infra/ansible/inventory/${ENVIRONNEMENT}/group_vars/all/all", text: "TypeName: ${TYPENAME_ENV}"
                    f = new File("/var/lib/jenkins/workspace/dev/infra/ansible/inventory/${ENVIRONNEMENT}/group_vars/all/all")
                    f.append( "\nREGION: ${REGION_ENV}" )
                    f.append( "\nKEYNAME: ${KEYNAME}" )
                    f.append( "\nansible_environnement: ${ENVIRONNEMENT}" )
                    f.append( "\nRootKey: ${ROOTKEY_ENV}" )
                    f.append( "\nJenkinsKey: ${JENKINS_KEY}" )
                    f.append( "\nAnsibleKey: ${ANSIBLE_KEY}" )
                    f.append( "\nsecret_devops: ${SECRETDEVOPS}" )
                    f.append( "\nSubnetIdPubADM: ${SUBNETIDPUBADM_ENV}" )
                    f.append( "\nSubnetIdPrivADM: ${SUBNETIDPRIVADM_ENV}" )
                    f.append( "\nSubnetIdPubDEV: ${SUBIDPUBDEV}" )
                    f.append( "\nSubnetIdPrivDEV: ${SUBIDPRIVDEV}" )
                    f.append( "\nSubnetIdPubQUA: ${SUBIDPUBQUA}" )
                    f.append( "\nSubnetIdPrivQUA: ${SUBIDPRIVQUA}" )
                    f.append( "\nSubnetIdPubPROD: ${SUBIDPUBPROD}" )
                    f.append( "\nSubnetIdPrivPROD: ${SUBIDPRIVPROD}" )
                    f.append( "\nVpcId: ${VPCID}" )
                    f.append( "\nPrivateIP: ${PRIVIP_ENV}" )
                    f.append( "\nIngressPort: ${INGRPORT}" )
                    f.append( "\nSecurityGroupNameList: ${SECGRPNLST}" )
                    f.append( "\nUrlscript: ${USCRIPT}" )
                    f.append( "\nSecurityGroupId: ${SECGRPID}" )
                    f.append( "\nInstanceType: ${INSTTYPE}" )
                    f.append( "\nAWSAccessKeyId: ${AWS_ACCESS_KEY}" )
                    f.append( "\nAWSSecretAccessKeyId: ${AWS_SECRET_KEY}" )
                    f.append( "\nDBName: ${DBNAME_ENV}" )
                }
             }
        }
// SUPPRESSION DE LA STACK qcmdev / qcmqua / qcmprod
        stage('deleteEC2byansible') {
            steps {

                    sh """#!/bin/bash -xe
                    sudo -u devops -s ansible-playbook -i /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/inventory/${ENVIRONNEMENT}/hosts /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/roles/common/tasks/cloudformation-delete.yml -vvv
                    sleep 5s
                    """
            }
        }
// CREATION DE LA STACK qcmdev / qcmqua / qcmprod
        stage('createEC2byansible') {
            steps {
                    sh """#!/bin/bash -xe
                    sudo -u devops -s ansible-playbook -i /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/inventory/${ENVIRONNEMENT}/hosts /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/roles/common/tasks/cloudformation-create.yml -vvv
                    """
            }
        }
// Creation du user devops + envoi de la clé ssh sur l'environnment qcmdev / qcmqua / qcmprod
        stage('DistribKeyByansible') {
            steps {
                    sh """#!/bin/bash -xe
                    sudo -u devops -s ansible-playbook -i /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/inventory/${ENVIRONNEMENT}/hosts /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/distribkey.yml --user ec2-user --key-file /home/devops/.ssh/projet1grp3key.pem -vvv
                    """
            }
        }
// Decompression du build + Test de creation de la BDD
        stage('installqcmTESTDB') {
            steps {
                    sh """#!/bin/bash -xe
                    sudo -u devops -s ansible-playbook -i /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/inventory/${ENVIRONNEMENT}/hosts /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/${ENVIRONNEMENT}.yml --extra-vars "adminnexus=${CREDENTIALS_NEXUS_USR} pwdnexus=${CREDENTIALS_NEXUS_PSW} userdb=${CREDENTIALS_DB_USR} pwddb=${CREDENTIALS_DB_PSW} namedb=${DBNAME_ENV} dnsdb=${DNSDBTEST_ENV} artifactId=${NEXUS_ARTIFACT_ID} groupId=${NEXUS_GROUP_ID} numbuild=${BUILD_NUMBER} dnsnexus=${DNSPUBEC2NEXUS_ENV} gotoqcm=no" -vvv
                    """
            }
        }
// Creation de la BDD
        stage('installqcmDB_&_startquizz') {
            steps {
                    sh """#!/bin/bash -xe
                    sudo -u devops -s ansible-playbook -i /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/inventory/${ENVIRONNEMENT}/hosts /var/lib/jenkins/workspace/${env.JOB_BASE_NAME}/infra/ansible/${ENVIRONNEMENT}.yml --extra-vars "userdb=${CREDENTIALS_DB_USR} pwddb=${CREDENTIALS_DB_PSW} namedb=${DBNAME_ENV} dnsdb=${DNSDB_ENV} gotoqcm=yes" -vvv
                    """
            }
        }

//RECUPERATION DU DNS PUBLIC de l'environnement pour le test de l'url
        stage('getdnspublicenv'){
            steps {
                script {
                    env.DNSPUBEC2ENV = "${sh(script:'chmod +x infra/getdnspubEC2id.sh && ./infra/getdnspubEC2id.sh ${TYPENAME_ENV} ${REGION_ENV}', returnStdout: true).trim()}"
                }
            }
        }
//TEST DU BUILD versionné
        stage('testurlquizz'){
            steps {
                sh 'sleep 2s'
                sh "echo http://${DNSPUBEC2ENV}:${INGRPORT}"
                sh "curl http://${DNSPUBEC2ENV}:${INGRPORT}"
            }
        }
    }
}
