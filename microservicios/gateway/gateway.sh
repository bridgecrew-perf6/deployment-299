#!/bin/bash
proyecto=""$1
entorno=""$2
version=""$3
groupid=com/mercurytfs/mercury/cloud/modules
artifactid=gateway.boot
serviceName=gateway
minimumMemory=128m
maximumMemory=256m
maxMemoryDeployment=768
waitFor=""
workspace=$proyecto$entorno
echo ""
echo ""
echo "+ 0. Lanzando despliegue de $serviceName "
echo "     - Workspace: $workspace"
echo "     - Version (vacío=latest): $version"
echo ""
echo ""
echo ""
entornos/$proyecto"_"$entorno".sh" $groupid $artifactid $serviceName ""$waitFor $minimumMemory $maximumMemory ""$version $proyecto $entorno $maxMemoryDeployment
