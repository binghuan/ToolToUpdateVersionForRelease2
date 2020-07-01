#!/bin/sh

pacakgeFile="app/package.json"
versionString=$(cat ${pacakgeFile} | grep -i -E "version")
echo "Check current version in file ${pacakgeFile}"
echo "${versionString}"

## Get version string.
originalVersion=$(cat ${pacakgeFile} | grep -i -E "version" | sed 's/\"version\": \"//g' | sed 's/\",//g' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^"//' -e 's/"$//')
echo "---------------------"
echo "version: _${originalVersion}_"
echo "---------------------"

## extract version number.
major=$(echo ${originalVersion} | cut -d "." -f 1)
minor=$(echo ${originalVersion} | cut -d "." -f 2)
revision=$(echo ${originalVersion} | cut -d "." -f 3)

newRevision=$(($revision + 1))

echo "update revision from ${revision} to ${newRevision}"
newVersion="${major}.${minor}.${newRevision}${deployEnv}"

echo "... replace Version from ${originalVersion} to ${newVersion}"
sed "s/\"version\": \"${originalVersion}\",/\"version\": \"${newVersion}\",/g" ${pacakgeFile} >tmp.json
mv -f tmp.json ${pacakgeFile}
echo "OK> Version has been updated."

echo "Ready to release new version for build stage SIT"
today=$(date +"%Y%m%d")
tagForSIT="SIT_${today}_"
echo "${tagForSIT}"
totalReleaseNumber=$(git tag -l "${tagForSIT}*" | wc -l)
targetReleaseNumber=$(($totalReleaseNumber + 1))
tagForSIT="SIT_${today}_${targetReleaseNumber}"
echo "New Tag = ${tagForSIT}"