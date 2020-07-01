#!/bin/sh

# if [ "$#" != 1 ]; then
#     echo "–"
#     echo "⚠ You must give me arguments for setup.\n"
#     echo "  ☞ Arg[1]: build Stage , ex: SIT/PRO/DEV"
#     echo "–"
#     exit 1
# fi

pacakgeFile="app/package.json"
configFile="resources/mac/config.json"
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

function commitWithTag() {
    echo "[START]-------------------------------------------------------------->"
    date 
    echo ""
    buildStage=$1
    echo "commitWithTag for build stage ${buildStage}"
    shortName=""
    case "$buildStage" in
    "SIT")
        echo "build stage is SIT"
        shortName="s"
        ;;
    "PRO")
        echo "build stage is PRODUCTION"
        shortName="p"
        ;;
    "DEV")
        echo "build stage is DEV"
        shortName="d"
        ;;
    *)
        echo "build stage is UNKNOWN"
        shortName=""
        exit 2
        ;;
    esac

    echo "{\"PLATFORM\": \"${shortName}\"}" >${configFile}
    git add ${configFile}
    git add ${pacakgeFile}
    git status
    git commit -m "Update version to release ${newVersion}"
    git push

    echo ">> tagForBuildStage: "
    echo "Ready to release new version for build stage ${buildStage}"
    YYYYMMDD=$(date +"%Y%m%d")
    tagForBuildStage="${buildStage}_${YYYYMMDD}_"
    echo "${tagForBuildStage}"
    totalReleaseNumber=$(git tag -l "${tagForBuildStage}*" | wc -l)
    targetReleaseNumber=$(($totalReleaseNumber + 1))
    tagForBuildStage="${buildStage}_${YYYYMMDD}_${targetReleaseNumber}"
    echo "New Tag = ${tagForBuildStage}"
    git tag -a ${tagForBuildStage} -m "Add tag to release ${newVersion}"
    git push --tags
    echo "[END]----------------------------------------------------------------<\n"
}

commitWithTag SIT
commitWithTag PRO
