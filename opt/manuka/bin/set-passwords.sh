#!/bin/bash
# variables
confDir=${1:-"./docker/traefik/etc/conf"}
traefikPWFile="$confDir/traefik.htpasswd"
kibanaPWFile="$confDir/kibana.htpasswd"
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
# response o/a
function response_OA () {
  promptString=$1
  read -r -p "$promptString [o/A] " answer
    if [[ "$answer" =~ ^([oO][vV][eE][rR][wW][rR][iI][tT][eE]|[oO])$ ]]; then
      response=1
    else
      response=0
    fi
}
# check pw file
function pw_Check () {
  if [[ -f $pwFile ]]; then
    file=1
  else
    file=0
  fi
}
# pw overwrite
function pw_Overwrite () {
  read -r -p "Enter username " username
    if htpasswd -c $pwFile $username; then
      echo "overwritten"
      changed=1
    else
      echo "failed to set htpasswd"
    fi  
}
# pw append
function pw_Append () {
  read -r -p "Enter username " username
      if htpasswd $pwFile $username; then
      echo "appended"
      changed=1
      else
        echo "failed to set htpasswd"
      fi
}
# pw set
function pw_Set () {
  pwFile=$1
  pw_Check
  if [[ $file = 1 ]]; then
    response_OA "Overwrite/Append existing config?"
    if [[ $response = 1 ]]; then
      pw_Overwrite
    else
      pw_Append
    fi
  else
    echo "htpasswd file not found."
  fi
}
# set passwords
response_YN "Setup Traefik Access Password?"
    if [[ $response = 1 ]]; then
      pw_Set $traefikPWFile
    fi
response_YN "Setup Kibana Access Password?"
    if [[ $response = 1 ]]; then
      pw_Set $kibanaPWFile
    fi
# restart traefik
if [[ $changed = 1 ]]; then
  response_YN "Restart Traefik Container?"
    if [[ $response = 1 ]]; then
      docker container restart traefik
    fi
fi