#!/bin/bash
#$5 tempDirName
server=http://user:password@IP:port/artifactory


groupid=$1
artifactid=$2
if [ -n "$3" ]; then
  repo=$3
else
  repo=libs-trunk-snapshots-local
fi
if [[ $repo == "libs-snapshots-local" || $repo == "libs-trunk-local" ||  $repo == "libs-release-local" ]]; then
  server=http://user:password@IP:port/artifactory
fi
if [ -n "$4" ]; then
  versionPrefix=$4
else
  versionPrefix=latest
fi
endTime=$(date +%s);
artifact=$groupid/$artifactid
path=$server/"$repo"/"$artifact"/

mkdir $5
tmpFile=$5/"$endTime".txt
tmpFile2=$5/"$endTime"_2.txt

touch $tmpFile
touch $tmpFile2

#echo "Versión requerida: $versionPrefix"

if [[ $(curl -s $path) == *"SNAPSHOT"* ]]; then
  curl -s $path | grep -w "<a href=\"\(\([0-9]\(\.[0-9]\+\)\+\)-SNAPSHOT\)" | sed "s/<a href=\"\(\([0-9]\(\.[0-9]\+\)\+\)-SNAPSHOT\).*/\1/" | sort -V > "$tmpFile"
else
  curl -s $path | grep -w "<a href=\"\([0-9]\(\.[0-9]\+\)\+\)\+" | sed "s/<a href=\"\([0-9]\(\.[0-9]\+\)\+\)\+.*/\1/" | sort -V > "$tmpFile"
fi

if [[ $versionPrefix == 'latest' || $versionPrefix == 'X' ]]; then
  versionCloud=$(awk '/./{line=$0} END{print line}' "$tmpFile")
else
  input=(./"$tmpFile")
  IFS='.' # Delimitador = punto
  read -ra VERSIONPREFIX <<< "$versionPrefix" #Almacenar en el array la versión que se está buscando (variable versionPrefix)

  while read line || [ -n "$line" ]; do
    if [ -n "$versionCloud" ]; then
      break
    fi

    currentLine="$line"
    IFS='.' # Delimitador = punto
    read -ra VERSION <<< "$currentLine" #Almacenar en el array la versión que se está leyendo del fichero (Ej: 1.20.5)
    for ((idx=0; idx<${#VERSION[@]}; ++idx)); do
      if [ "${VERSIONPREFIX[idx]}" == 'X' ]; then #Buscar versión mayor dentro del rango de la variable "version"
        chrlen=${#versionPrefix}
        len="$(($chrlen-2))"
        version=$(echo $versionPrefix | cut -c1-"$len")
        IFS=' ' # Delimitador = espacio
        read -ra VERSIONTMP <<< "$version" #Almacenar en el array la versión que se está buscando (variable versionPrefix)
        regex=""
        for ((index=0; index<${#VERSIONTMP[@]}; ++index)); do
          if [ $index == 0 ]; then
            regex+="^"
          fi
          if [ $((index+1)) == ${#VERSIONTMP[@]} ]; then
            regex+="${VERSIONTMP[index]}"".*"
          else
            regex+="${VERSIONTMP[index]}""[. ]"
          fi
        done
        #echo "REGEX: $regex"
        cat "$tmpFile" | grep -w "$regex" | sort -V > "$tmpFile2"
        versionCloud=$(awk '/./{line=$0} END{print line}' "$tmpFile2")
        break
      elif [[ "${VERSIONPREFIX[idx]}" != *"X"* ]]; then
        version=$versionPrefix
        IFS='[. ]' # Delimitador = espacio/punto
        read -ra VERSIONTMP <<< "$version" #Almacenar en el array la versión que se está buscando (variable versionPrefix)
        regex=""
        for ((index=0; index<${#VERSIONTMP[@]}; ++index)); do
          if [ $index == 0 ]; then
            regex+="^"
          fi
          if [[ $((index+1)) == ${#VERSIONTMP[@]} && "${VERSIONTMP[index]}" != *"X"* ]]; then
            regex+="${VERSIONTMP[index]}"
          elif [[ $((index+1)) == ${#VERSIONTMP[@]} ]]; then
            regex+=".*"
          else
            regex+="${VERSIONTMP[index]}""[. ]"
          fi
        done
        #echo "REGEX: $regex"
        cat "$tmpFile" | grep -w "$regex" | sort -V > "$tmpFile2"
        versionCloud=$(awk '/./{line=$0} END{print line}' "$tmpFile2")
        break
      elif [ "${VERSION[idx]}" != "${VERSIONPREFIX[idx]}" ]; then
        break
      fi
    done
  done < "$input"
fi

#echo "Versión final: $versionCloud"

url=$path$versionCloud/
curl -s "$url" | grep -w ".*>\(.*\.jar\)<.*" | sed "s/.*>\(.*\.jar\)<.*/\1/" > "$tmpFile"
jar=$(awk '/./{line=$0} END{print line}' "$tmpFile")
jar=$(echo "$jar" | sed 's/ /./g')
url=$url$jar

rm -rf "$tmpFile"
rm -rf "$tmpFile2"

echo "$jar""|""$url""|""$versionCloud"
