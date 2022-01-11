#!/bin/bash

#Parámetros:
# $1 - URL del grupo en el artifactory (Ej: com/mercurytfs/mercury/cloud/web)
# $2 - ID del artefacto .web.all (Ej: accounting.jobs.web.all)
# $3 - Nombre del servicio (Ej: accountingjobs)el directorio en mercury.deploy debe de nombrarse igual.
# $4 - Servicio a ejecutar en el wait-for-it.sh (Ej: scheduler)
# $5 - Parámetro mínimo de memoria Docker (Ej: 256m)
# $6 - Parámetro máximo de memoria Docker (Ej: 350m)
# $7 - Perfil activo (Ejs: dev, gts,...)
# $8 - Version del artefacto o label.
# $9 - Workspace, debe de ser proyecto + entorno por ejemplo productodev o gtsdev. Servira como nameSpace en kubernetes
# $10 - URL de SVN. Si este parámetro viene vacío, la URL por defecto es libs-trunk-snapshots-local.
# $11 - URL de GIT (Ej: libs-snapshot-local para la rama DEV, libs-trunk-snapshots-local para la rama MASTER)
# $12 - Rama del config server que se debe de usar.
# $13 - Fichero en el que se definiran los artefactos que es necesario meter en el classpath.
# $14 - Imagen base
# $15 - Service Port normalmente 8080 excepto en el caso de gateway que dependerá del entorno y proyecto.
# $16 - Tipo de servicio Normalmente CLusterIP excepto en el caso de Gateway que será NodePort
# $17 - Repositorio desde que se descarga el JAR del microservicio.
# $18 - Perfil que levanta todas las integraciones (isIntegrated)
# $19 - Maxima memorai del contenedor

groupid=$1
artifactid=$2
serviceName=$3
waitFor=$4
minimumMemory=$5
maximumMemory=$6
activeProfile=$7
version=$8
workspace=${9}
repoSVN=${10}
repoGIT=${11}
activeLabel=${12}
classpathFile=${13}
baseImage=${14}
servicePort=${15}
serviceType=${16}
repoJar=${17}
secondProfile=${18}
maxMemoryDeployment=${19}
nameFile="${serviceName//./_}"
nameFileService=service-$nameFile
dockerFileName=Dockerfile-$nameFile
pathMSJar=/opt/externallibs/
pathClasspath=/opt/classpath_lib/
tempDirName=$serviceName$activeProfile

echo "+ 1. Parametros de la ejecucion"
echo ""
echo "     - Group id ms: $groupid"
echo "     - Artifactid ms: $artifactid"
echo "     - Nombre ms en kube: $serviceName"
echo "     - Version ms (vacio latest): $version"
echo "     - Repo del ms: $repoJar"
echo "     - Esperara al ms: $waitFor"
echo "     - Max mem: $maximumMemory"
echo "     - Min mem: $maximumMemory"
echo "     - Perfil activo: $activeProfile"
echo "     - Rama configServer: $activeLabel"
echo "     - Workspace/Namespace: $workspace"
echo "     - Fichero de classpath $classpathFile"
echo "     - Repo classpath svn: $repoSVN"
echo "     - Repo classpath git: $repoGIT"
echo "     - Imagen Base: $baseImage"
echo "     - Puerto Servicio: $servicePort"
echo "     - Tipo Servicio: $serviceType"
echo "     - tempDirName: $tempDirName"
echo ""
echo ""
echo "2. Borrando services y deployment"
kubectl delete deployment.apps/$serviceName --namespace=$workspace
kubectl delete service/"remotedebug-"$serviceName"-"$workspace --namespace=$workspace
kubectl delete service/$serviceName --namespace=$workspace
echo ""
echo ""
allInfoBoot=$(./generateDownloadPath.sh $groupid $artifactid $repoJar $version $tempDirName)

echo "+ 3. Jar que se va a utilizar para el Microservicio"
jarBoot=$(echo $allInfoBoot | cut -d "|" -f 1)
urlBoot=$(echo $allInfoBoot | cut -d "|" -f 2)
versionBoot=$(echo $allInfoBoot | cut -d "|" -f 3)

echo "     - Jar          --> " $jarBoot
echo "     - Version      --> " $versionBoot
echo "     - Url Descarga --> " $urlBoot
echo ""
echo ""

rm -r -f ./microservicios/$serviceName/$workspace/jar || true
mkdir -p ./microservicios/$serviceName/$workspace/jar
#downloadScript="wget -q -N $urlBoot;mv $jarBoot $pathMSJar;"
downloadScript=(/usr/local/addToClasspath.sh $groupid $artifactid $serviceName $serviceName $repoJar $pathMSJar $version)";";#mv $jarBoot $pathMSJar$jarBoot;";
echo "+ 4. Artefactos que se incluiran en el classpath"
echo ""
input=(./microservicios/$serviceName/$classpathFile)
while read line || [ -n "$line" ]; do
  currentLine="$line"
  [[ -z $line || $currentLine =~ ^#.* ]] && continue # Si la línea empieza por el carácter '#', se ignora.
  IFS=' ' # Delimitador = espacio
  read -ra CLASSPATH <<< "$currentLine" #Almacenar en el array el nombre, groupId, artifactId y si se descarga de SVN o de GIT
  for ((idx=0; idx<${#CLASSPATH[@]}; ++idx)); do
    if [ "$idx" == 0 ]; then
      classpathJarName="${CLASSPATH[idx]}"
    elif [ "$idx" == 1 ]; then
      classpathGroupId="${CLASSPATH[idx]}"
    elif [ "$idx" == 2 ]; then
      classpathArtifactId="${CLASSPATH[idx]}"
    elif [ "$idx" == 3 ]; then
      repo="${CLASSPATH[idx]}"
    elif [ "$idx" == 4 ]; then
      version="${CLASSPATH[idx]}"
    fi
  done
  if [ -z $version ]; then
    version="latest"
  fi
  echo "     - Name: $classpathJarName"
  echo "        GoupId: $classpathGroupId"
  echo "        ArtefactId: $classpathArtifactId"
  echo "        Version(vacio=latest): $version"
  echo "        Repositorio: $repo"
  if [ $repo == 'SVN' ]; then
    if [[ $classpathJarName == *"Multicast"* || $classpathJarName == *"ActiveMQ" || $classpathJarName == *"MQSERIES" ]]; then
      downloadScript=$downloadScript"(/usr/local/addToClasspath.sh $classpathGroupId $classpathArtifactId $serviceName $classpathJarName libs-release-local $pathClasspath $version);"
    else
      downloadScript=$downloadScript"(/usr/local/addToClasspath.sh $classpathGroupId $classpathArtifactId $serviceName $classpathJarName $repoSVN $pathClasspath $version);"
    fi
  elif [ $repo == 'GIT' ]; then
    if [[ $classpathJarName == *"Multicast"* || $classpathJarName == *"ActiveMQ" || $classpathJarName == *"MQSERIES" ]]; then
      downloadScript=$downloadScript"(/usr/local/addToClasspath.sh $classpathGroupId $classpathArtifactId $serviceName $classpathJarName libs-release-local $pathClasspath $version);"
    else
      downloadScript=$downloadScript"(/usr/local/addToClasspath.sh $classpathGroupId $classpathArtifactId $serviceName $classpathJarName $repoGIT $pathClasspath $version);"
    fi
  else
    echo "Error añadiendo "$classpathJarName" al classpath. Es necesario especificar SVN/GIT."
  fi
done < "$input"

if [ -n "$waitFor" ]; then
  #commandList="[\/bin\/bash, -c, $downloadScript \/usr\/local\/wait-for-it.sh "$waitFor"; \/usr\/local\/initcontainer.sh]"
  commandList="[/bin/bash, -c, $downloadScript /usr/local/wait-for-it.sh "$waitFor"; /usr/local/initcontainer.sh]"
else
#  commandList="[\/bin\/bash, -c,$downloadScript \/usr\/local\/initcontainer.sh]"
  commandList="[/bin/bash, -c,$downloadScript /usr/local/initcontainer.sh;while sleep 1000; do echo '1'; done]"

fi
echo "En el caso de activemq o mqseries se forzara a descargar solo releases debido a errores que proporcionan los ultimos snapshots "
ESCAPED_COMMAND=$(echo $commandList | sed -e 's/[\/&]/\\&/g')
echo ""
echo ""
echo "+ 5. Generando yml del deployment generic_kubernete_deployment.yml..."
echo ""
cp generic_kubernete.yml microservicios/$serviceName/$workspace/"$nameFile.yml"
sed -i 's/microserviceName/'$serviceName'/g' microservicios/$serviceName/$workspace/"$nameFile.yml"
sed -i 's%imageLink%'$baseImage'%g' microservicios/$serviceName/$workspace/"$nameFile.yml"
sed -i "s/commandList/$ESCAPED_COMMAND/g" microservicios/$serviceName/$workspace/"$nameFile.yml"
sed -i "s/URI_CONFIG_SERVER/http\:\/\/192.168.10.11\:8888/g" microservicios/$serviceName/$workspace/"$nameFile.yml"
sed -i "s/TOKEN_CONFIG_SERVER/s.b4TDkmPaDHPZo7uOlffKpy5I/g" microservicios/$serviceName/$workspace/"$nameFile.yml"
sed -i "s/LABEL_CONFIG_SERVER/$activeLabel/g" microservicios/$serviceName/$workspace/"$nameFile.yml"
if [ -z $secondProfile ]; then
  sed -i "s/PROFILE_CONFIG_SERVER/$activeProfile/g" microservicios/$serviceName/$workspace/"$nameFile.yml"
else
  sed -i "s/PROFILE_CONFIG_SERVER/$secondProfile,$activeProfile/g" microservicios/$serviceName/$workspace/"$nameFile.yml"
fi

sed -i 's/memoryGeneric/-Xms'$minimumMemory' -Xmx'$maximumMemory'/g' microservicios/$serviceName/$workspace/"$nameFile.yml"
sed -i 's/maxMemory/'$maxMemoryDeployment'Mi/g' microservicios/$serviceName/$workspace/"$nameFile.yml"
if [ $serviceName = 'gateway' ]; then
  #sed -i "s/#//g" microservicios/$serviceName/$workspace/"$nameFile.yml"
  sed -i "s/8080/9999/g" microservicios/$serviceName/$workspace/"$nameFile.yml"
fi
cat "microservicios/$serviceName/$workspace/$nameFile.yml"
echo ""
echo ""
echo "+ 6. Generando yml del servicio generic_kubernete_service.yml..."
echo ""
nameFileService=$nameFile\_kubernete_service
cp generic_kubernete_service.yml ./microservicios/$serviceName/$workspace/"$nameFileService.yml"
sed -i 's/servicename/'$serviceName'/g' microservicios/$serviceName/$workspace/"$nameFileService.yml"
sed -i 's/serviceType/'$serviceType'/g' microservicios/$serviceName/$workspace/"$nameFileService.yml"

if [[ $serviceName == "gateway" ]]; then
    sed -i "s/\(\#\)\( *nodePort\)/\2/g" microservicios/$serviceName/$workspace/"$nameFileService.yml"
    sed -i 's/9999/'$servicePort'/g' microservicios/$serviceName/$workspace/"$nameFileService.yml"
    sed -i 's/servicePort/9999/g' microservicios/$serviceName/$workspace/"$nameFileService.yml"
else
  sed -i 's/servicePort/'$servicePort'/g' microservicios/$serviceName/$workspace/"$nameFileService.yml"
fi
cat microservicios/$serviceName/$workspace/"$nameFileService.yml"

echo ""
echo ""
echo "+ 7. Desplegando service y deployment"
echo ""

kubectl apply -f microservicios/$serviceName/$workspace/"$nameFile.yml" --namespace=$workspace

if [[ $serviceName == "gateway" ]]; then
  echo "Esperar 30 sec para que el puerto del gateway quede en deshuso."
  sleep 30
  result=$(kubectl apply -f microservicios/$serviceName/$workspace/"$nameFileService.yml" --namespace=$workspace)
  while [ "$result" != "service/gateway created" ]
  do
    echo "Esperar 15 sec más para que el puerto del gateway quede en deshuso."
    sleep 15
    result=$(kubectl apply -f microservicios/$serviceName/$workspace/"$nameFileService.yml" --namespace=$workspace)
  done
  echo $result
else
  kubectl apply -f microservicios/$serviceName/$workspace/"$nameFileService.yml" --namespace=$workspace
fi
#numPods=$(kubectl get pods --selector app=$serviceName --namespace=$workspace | tail -n +2 | wc -l)

#while [ "$numPods" != "1" ]
#do
#  echo "Esperar 10 sec exponer el debug remoto, el pod viejo aun existe.."
#  sleep 10
# numPods=$(kubectl get pods --selector app=$serviceName --namespace=$workspace | tail -n +2 | wc -l)
#done
#
kubectl expose deployment.apps/$serviceName --type=NodePort --name="remotedebug-"$serviceName"-"$workspace --namespace=$workspace

echo ""
echo ""
echo "+ 8. Borrando directorios dentro de /microservicios/$serviceName/$workspace..."
echo ""
rm -r -f microservicios/$serviceName/$workspace/jar
rm -r -f microservicios/$serviceName/$workspace/dependencies
rm -r -f microservicios/$serviceName/$workspace/scripts
rm -r -f  microservicios/$serviceName/$workspace/classpath
rm -f microservicios/$serviceName/$workspace/"$nameFile.yml"
rm -f microservicios/$serviceName/$workspace/$dockerFileName
rm -f microservicios/$serviceName/$workspace/"$nameFileService.yml"

serviceCreated=$(kubectl get service "remotedebug-"$serviceName"-"$workspace --namespace=$workspace | tail -n +2)
portExposed=$(sed -E 's/(.+)8000:([0-9]+)(.+)/\2/' <<< $serviceCreated)


nodeExposed=$(kubectl get pods -o wide --selector app=$serviceName --namespace=$workspace | tail -n +2 | awk '{ print $7 }')

#ipExposed=$(kubectl get nodes -o wide | grep $nodeExposed | awk '{ print $6 }')
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo ""
echo ""
echo "DESPLIEGUE FINALIZADO"
echo ""
echo ""
echo "Para ver los logs ejecutar:"
echo "kubectl logs -f deployment/"$serviceName "-n "$workspace
echo ""
echo ""
echo "Para conectarte por debug remoto:"
echo "IP: "$ipExposed
echo "Puerto: "$portExposed
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
