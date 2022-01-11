#!/bin/bash

#Parámetros:
# $1 - URL del grupo en el artifactory (Ej: com/mercurytfs/mercury/cloud/integration)
# $2 - ID del artefacto (Ej: interceptors.integration.service)
# $3 - Nombre del artefacto (Ej: collimp)
# $4 - Nombre del artefacto que se va a incluir en el classpath (Ej: Interceptor, SwiftManager)
# $5 - Indica el repositorio de donde se va a descargar el artefacto (Ej: libs-snapshots-local)
# $6 - Indica el path donde se va a mover el artefacto, puede ser /opt/classpath_lib
# $7 - Indica el prefijo de la version o latest.
groupId=$1
artifactId=$2
name=$3
artifactName=$4
repoName=$5
path=$6
versionPrefix=$7
echo "Adding "$artifactName" to classpath..."
echo "Using "$repoName" repository"
info=$(/usr/local/generateDownloadPath.sh $groupId $artifactId $repoName $versionPrefix)
#echo "INFO: $info"
jar=$(echo $info | cut -d "|" -f 1)
url=$(echo $info | cut -d "|" -f 2)
version=$(echo $info | cut -d "|" -f 3)
echo $artifactName" Jar --> " $jar
echo $artifactName" Url --> " $url
echo $artifactName" Version --> " $version
curl $url > /tmp/$jar
mv /tmp/$jar $path
chmod 777 $path/$jar
# mv $jar /opt/classpath_lib/
echo $artifactName" added to classpath."
server=http://user:password@IP:port/artifactory
