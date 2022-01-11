#!/bin/bash

#Parámetros:
# $1 - URL del grupo en el artifactory (Ej: com/mercurytfs/mercury/cloud/web)
# $2 - ID del artefacto .web.all (Ej: accounting.jobs.web.all)
# $3 - Nombre del servicio (Ej: accountingjobs)el directorio en mercury.deploy debe de nombrarse igual.
# $4 - Servicio a ejecutar en el wait-for-it.sh (Ej: scheduler)
# $5 - Parámetro mínimo de memoria Docker (Ej: 256m)
# $6 - Parámetro máximo de memoria Docker (Ej: 350m)
# $7 - Version del artefacto o label.
# $8 - Service Port normalmente 8080 excepto en el caso de gateway que dependerá del entorno y proyecto.
# $9 - Tipo de servicio Normalmente CLusterIP excepto en el caso de Gateway que será NodePort
# $9 - Fichero en el que se definiran los artefactos que es necesario meter en el classpath.
# $10 - Memoria maxima del contenedor

groupid=$1
artifactid=$2
serviceName=$3
waitFor=$4
minimumMemory=$5
maximumMemory=$6

if [[ $serviceName = 'importlc' || $serviceName = 'exportlc' || $serviceName = 'collectionsimport' || $serviceName = 'collectionsexport' || $serviceName = 'loans' || $serviceName = 'cloud' ]]; then
  activeProfile=gtsqa
else
  activeProfile=qa
fi

version=$7
servicePort=8080
serviceType=ClusterIP
proyecto=${8}
entorno=${9}
maxMemoryDeployment=${10}
workspace=$proyecto$entorno
secondProfile="isIntegrated"
classpathFile="addToClasspath_"$proyecto"_"$entorno".txt"
activeLabel=gts
baseImage=harbor.mercury-tfs.com/mercury/javase:latest
# Repositorio del que se descargaran los artefactos que vayan en el classpath de svn.
repoSVN=gts-libs-release-local
# Repositorio del que se descargaran los artefactos que vayan en el classpath de git.
repoGIT=gts-libs-release-local
# Repositorio del que se descargara el artefacto principal.
repoJar=gts-libs-release-local
# En el caso de necesitar redefinir para 1 entorno concreto algun Parametros
# ex. para Sanesback, el group id será distinto, se puede redefinir y pasarlo
# como parametro al genericSh en este fichero.
if [ $serviceName = 'gateway' ]; then
  serviceType="NodePort"
  servicePort="9997"
fi
dir=\""$(pwd)\""
sudo su - jenkinsdev -c "cd $dir;(./genericSh.sh $groupid $artifactid $serviceName \"\"$waitFor $minimumMemory $maximumMemory $activeProfile \"\"$version $workspace \"\"$repoSVN \"\"$repoGIT $activeLabel $classpathFile $baseImage $servicePort $serviceType $repoJar $secondProfile $maxMemoryDeployment $minMemoryDeployment)"
