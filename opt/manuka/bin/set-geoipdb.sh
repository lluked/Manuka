#!/bin/bash
# variables
configFile=${1:-"./docker/elastic/logstash/share/pipeline/2_filter_geoip.conf"}
ASNDBFile="./usr/share/logstash/db/GeoLite2-ASN.mmdb"
CityDBFile="./usr/share/logstash/db/GeoLite2-City.mmdb"
ASNDBMount="/usr/share/logstash/db/GeoLite2-ASN.mmdb"
CityDBMount="/usr/share/logstash/db/GeoLite2-City.mmdb"
# response y/n
function response_YN () {
  promptString=$1
  read -r -p "$promptString [y/N] " answer
    if [[ "$answer" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      response=1
    else
      response=0
    fi
}
# db check
function db_Check () {
  if [[ -f $dbFile ]]; then
    db=1
  else
    db=0
  fi
}
# config check
function config_Check () {
  if [[ -f $configFile ]]; then
    if grep -q 'default_database_type => "'"$dbType"'"' $configFile; then
      configType=1
    elif grep -q 'database => "'"$dbMount"'"' $configFile; then
      configType=2
    else
      configType=0
    fi
  else
    echo "No config file present at $configFile"
    exit
  fi
}
# set external db
function db_SetExternal () {
  sed -i 's|default_database_type => "'"$dbType"'"|database => "'"$dbMount"'"|' $configFile
}
# set default db
function db_SetDefault () {
  sed -i 's|database => "'"$dbMount"'"|default_database_type => "'"$dbType"'"|' $configFile
}
# set config
function config_Set () {
  dbType=$1
  dbFile=$2
  dbMount=$3
  db_Check $dbFile
  config_Check $configFile $dbType $dbMount
  if [[ $db = 1 ]]; then
    if [[ $configType = 1 ]]; then
      response_YN "Set $dbType DB to external?"
      if [[ $response = 1 ]]; then
        if db_SetExternal $configFile $dbType; then
          echo "$dbType DB set to" $dbMount
          changed=1
        fi
      fi
    elif [[ $configType = 2 ]]; then
      response_YN "Set $dbType DB to default?"
      if [[ $response = 1 ]]; then
        if db_SetDefault $configFile $dbType; then
          echo "$dbType DB set to default."
          changed=1
        fi
      fi
    else
      echo $dbType "DB configuration is invalid, please check." $configFile
    fi
  else
    if [[ $configType = 1 ]]; then
    echo "No external $dbType DB present, configuration remains unchanged."
    elif [[ $configType = 2 ]]; then
      echo "No external $dbType DB present, resetting to default..."
      if set_DefaultDB $configFile $dbType; then
        echo "$dbType DB set to default."
        changed=1
      fi
    else
      echo "$dbType DB configuration is invalid, please check." $configFile
    fi
  fi
}
# set config
response_YN "Setup ASN GeoIP DB?"
    if [[ $response = 1 ]]; then
      config_Set "ASN" $ASNDBFile $ASNDBMount
    fi
response_YN "Setup City GeoIP DB?"
    if [[ $response = 1 ]]; then
      config_Set "City" $CityDBFile $CityDBMount
    fi
# restart logstash
if [[ $changed = 1 ]]; then
  response_YN "Restart logstash Container?"
  if [[ $response = 1 ]]; then
    docker container restart logstash
  fi
fi