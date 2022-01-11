if [ -d /opt/optionslibs ]
then
	for x in $(ls -d /opt/optionslibs/*)
	do
		if [[ $x == *.jar ]]
		then
			if [[ -z $MSLIBS ]]
			then
				export MSLIBS=$x;
			else
				export MSLIBS=$MSLIBS:$x;
			fi
		fi
	done
else
	echo "Warning: optionslibs doesn't exist so maybe no configuration is available"
fi

for x in $(ls -d /opt/externallibs/*)
do
	if [[ -z $MSLIBS ]]
	then
		export MSLIBS=$x;
	else
		export MSLIBS=$MSLIBS:$x;
	fi
done
for y in $(ls -d /opt/classpath_lib/*)
do
	if [[ -z $CLASSPATHLIBS ]]
	then
		export CLASSPATHLIBS=$y;
	else
		export CLASSPATHLIBS=$CLASSPATHLIBS,$y;
	fi
done
if [ $RUN_MODE = "spring_boot_war" ]
then

	java $JAVA_OPT -cp $MSLIBS org.springframework.boot.loader.WarLauncher
elif [ $RUN_MODE = "spring_boot_jar" ]
then
	echo "Librerias en classpath: "
	echo $CLASSPATHLIBS
	echo "Libreria a desplegar: "
	echo $MSLIBS
	echo "Comando java: "
	echo "java $JAVA_OPT -Dloader.path=$CLASSPATHLIBS -XX:NativeMemoryTracking=detail -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9030 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.rmi.port=9030 -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000 -javaagent:/opt/classpath_lib/jmx_prometheus_javaagent-0.12.0.jar=8161:/opt/classpath_lib/prometheus_agent_config.yaml -cp $MSLIBS org.springframework.boot.loader.PropertiesLauncher"
	java $JAVA_OPT -Dloader.path=$CLASSPATHLIBS -XX:NativeMemoryTracking=detail -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9030 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.rmi.port=9030 -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000 -javaagent:/opt/classpath_lib/jmx_prometheus_javaagent-0.12.0.jar=8161:/opt/classpath_lib/prometheus_agent_config.yaml -cp $MSLIBS org.springframework.boot.loader.PropertiesLauncher
else
	/bin/bash -c "$CONTAINER_CMD"
fi
