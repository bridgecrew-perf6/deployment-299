#!/bin/bash
proyecto=""$1
entorno=""$2
version=""$3
groupid=com/mercurytfs/mercury/cloud/web
artifactid=loans.web.all
serviceName=loans
minimumMemory=120m
maximumMemory=1024m
maxMemoryDeployment=2200
waitFor="collectionsexport"
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
