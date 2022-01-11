#!/bin/bash
#maxMemoryDeployment en MB sin letra al final
proyecto=""$1
entorno=""$2
version=""$3
groupid=com/mercurytfs/mercury/cloud/web
artifactid=exportlc.web.all
serviceName=exportlc
minimumMemory=120m
maximumMemory=1024m
maxMemoryDeployment=2200
waitFor="importlc"
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
