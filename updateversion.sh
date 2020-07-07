#!/bin/sh

# if [ "$#" != 1 ]; then
#     echo "–"
#     echo "⚠ You must give me arguments for setup.\n"
#     echo "  ☞ Arg[1]: build Stage , ex: SIT/PRO/DEV"
#     echo "–"
#     exit 1
# fi

git pull

pacakgeFile="app/package.json"
configFile="resources/mac/config.json"

function checkFileExist() {
    targetFile=$1
    if [ -f "${targetFile}" ]; then
        echo "OK> File ${targetFile} was found."
    else
        echo "NG> File ${targetFile} was not found."
        exit 2
    fi
}

checkFileExist ${pacakgeFile}
checkFileExist ${configFile}

function commitWithTag() {
    echo "[START]-------------------------------------------------------------->"
    date
    echo ""
    buildStage=$1
    echo "Commit with Tag for build stage ${buildStage}"
    shortName=""
    case "$buildStage" in
    "SIT")
        echo "Build stage is SIT"
        shortName="s"
        ;;
    "PRO")
        echo "Build stage is PRODUCTION"
        shortName="p"
        ;;
    "DEV")
        echo "Build stage is DEV"
        shortName="d"
        ;;
    *)
        echo "Build stage is UNKNOWN"
        shortName=""
        exit 3
        ;;
    esac

    echo "{\"PLATFORM\": \"${shortName}\"}" >${configFile}
    git add ${configFile}
    git add ${pacakgeFile}
    git status
    git commit -m "Update version to release ${newVersion}"
    git push

    echo "-> Ready to release new version for build stage ${buildStage}"
    YYYYMMDD=$(date +"%Y%m%d")
    tagForBuildStage="${buildStage}_${YYYYMMDD}_"
    echo "${tagForBuildStage}"
    totalReleaseNumber=$(git tag -l "${tagForBuildStage}*" | wc -l)
    targetReleaseNumber=$(($totalReleaseNumber + 1))
    tagForBuildStage="${buildStage}_${YYYYMMDD}_${targetReleaseNumber}"
    echo "New Tag = ${tagForBuildStage}"
    git tag -a ${tagForBuildStage} -m "Version ${newVersion}"
    git push origin ${tagForBuildStage}
    echo "[END]----------------------------------------------------------------<\n"
}

function updateVersion() {
    ## ---------------------------------------------------------------------------->
    versionString=$(cat ${pacakgeFile} | grep -i -E "version")
    echo "-> Check current version in file ${pacakgeFile}"
    echo "${versionString}"

    ## Get version string.
    originalVersion=$(cat ${pacakgeFile} | grep -i -E "version" | sed 's/\"version\": \"//g' | sed 's/\",//g' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^"//' -e 's/"$//')
    echo "-----------------------------"
    echo "version: _${originalVersion}_"
    echo "-----------------------------"

    ## extract version number.
    major=$(echo ${originalVersion} | cut -d "." -f 1)
    minor=$(echo ${originalVersion} | cut -d "." -f 2)
    revision=$(echo ${originalVersion} | cut -d "." -f 3)

    newRevision=$(($revision + 1))

    echo "Update revision from ${revision} to ${newRevision}"
    newVersion="${major}.${minor}.${newRevision}${deployEnv}"

    echo "Replace Version from ${originalVersion} to ${newVersion}"
    sed "s/\"version\": \"${originalVersion}\",/\"version\": \"${newVersion}\",/g" ${pacakgeFile} >tmp.json
    mv -f tmp.json ${pacakgeFile}
    echo "OK> Version has been updated."
    ## ----------------------------------------------------------------------------<

    if [ $((newRevision % 2)) -eq 0 ]; then
        echo "Number is even."
        commitWithTag PRO

    else
        echo "Number is odd."
        commitWithTag SIT
    fi
}

updateVersion
updateVersion