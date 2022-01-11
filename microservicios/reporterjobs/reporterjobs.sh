#!/bin/bash
proyecto=""$1
entorno=""$2
version=""$3
groupid=com/mercurytfs/mercury/cloud/web
artifactid=reporter.jobs.web.all
serviceName=reporterjobs
minimumMemory=256m
maximumMemory=380m
maxMemoryDeployment=1024
waitFor="scheduler"
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
