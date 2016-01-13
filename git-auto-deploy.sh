#!/bin/sh

listCommands()
{
    echo "usage: git-auto-deploy <command> [<args>]"
    echo "usage: git deploy <command> [<args>]"
    echo ""
    echo "Available commands:"
    echo "\td OR deploy\t\t Deploy the latest tag"
    echo "\tl OR list\t\t List all available tags"
    echo "\ts OR add-script [<args>] Add script to run before or after deployment"
    echo "\th OR help\t\t Help"
    echo ""
}

config()
{
    git config gitauto.deploy.prefix "qa"
    git config gitauto.deploy.status "deploy"
}

init()
{
    local $_tagPrefix=$1
    local initTagPrefix="$(git config --get gitauto.deploy.prefix)"

    # git fetch --all
    # git pull
    # git pull --tags

    if [ -z "$initTagPrefix" ]; then
        config
        initTagPrefix="$(git config --get gitauto.deploy.prefix)"
        deployStatus="$(git config --get gitauto.deploy.status)"
    fi

    eval $_tagPrefix="'$initTagPrefix'"
    echo deployStatus
}

addScript()
{
    git config gitauto.deploy.script-"$2" "$1"
    echo "Added script will be executed $2 deployment"
    echo "Actual script: $1"
}

list()
{
    git tag -l
}

hault()
{
    git tag -l
}

resume()
{
    git tag -l
}

execScript()
{
    local _result=$1
    local scriptResult=''
    local retStatus=0

    scriptResult="$(eval $3)"
    exitStatus=$?

    if [ $exitStatus -gt 0 ]; then
        retStatus=$exitStatus
    fi
    # eval _result=\"'$scriptResult'\"
    # echo $_result
    return $exitStatus
}

deploy()
{
    local scriptBefore="$(git config --get gitauto.deploy.script-before)"
    local scriptAfter="$(git config --get gitauto.deploy.script-after)"
    local result=''
    local exitStatus=0
    local retStatus=0;

    if [ ! -z "$scriptBefore" ]; then
        printf "Pre-Deployment Script: "
        execScript "$result" "before" "$scriptBefore"
        exitStatus=$?
        if [ $exitStatus -gt 0 ]; then
            retStatus=$exitStatus
            printf "FAILED with errors\n"
        else
            printf "SUCCESSED\n"
        fi
    fi

    printf "Code Deployment using GIT TAG ($1): "
    if [ $exitStatus -eq 0 ]; then
        deployResult=$(git checkout "TEST$1" 2>&1)
        codeDeployStatus=$?
        if [ $codeDeployStatus -gt 0 ]; then
            retStatus=$exitStatus
            printf " FAILED\n"
        else
            printf " SUCCESSED\n"
        fi
    else
        printf "STOPPED\n"
    fi

    if [ ! -z "$scriptAfter" ]; then
        if [ $exitStatus -eq 0 ]; then
            printf "Post-Deployment Script: "
            execScript "$result" "after" "$scriptAfter"
            exitStatus=$?
            if [ $exitStatus -gt 0 ]; then
                retStatus=$exitStatus
                printf "FAILED with errors\n"
            else
                printf "SUCCESSED\n"
            fi
        else
            printf "STOPPED\n"
        fi
    fi

    return $retStatus
}

getLatestTag()
{
    selectedTag=''
    selectedTagDate="1969-01-01"
    selectedTagTime='00:00:00'
    selectedTagDateTimestamp=$(date --utc -d "$selectedTagDate $selectedTagTime" +"%Y%m%d%H%M%S")

    for tag in "${tagsList[@]}" ; do
        IFS='-' read -a tagSplit <<< "$tag"
        if [ "$1" = "${tagSplit[0]}" ]; then
            tagDate="${tagSplit[1]}-${tagSplit[2]}-${tagSplit[3]}"
            tagTime="${tagSplit[4]}:${tagSplit[5]}:${tagSplit[6]}"

            tagDateTimestamp=$(date --utc -d "$tagDate $tagTime" +"%Y%m%d%H%M%S")
            if [ $tagDateTimestamp -ge $selectedTagDateTimestamp ]; then
                selectedTagDateTimestamp=$tagDateTimestamp
                selectedTag=$tag
            fi
        fi
    done
    if [ $selectedTagDateTimestamp = $(date --utc -d "$selectedTagDate $selectedTagTime" +"%Y%m%d%H%M%S") ]; then
        echo "No tags with valid datetime stamp were found"
        exit
    fi
    echo $selectedTag
}

tagPrefix="qa"
tagsList=($(git tag -l))

# init $tagPrefix
if [ ! -z "$1" ]; then
    if [ "$1" = "d" ] || [ "$1" = "deploy" ]; then
        deploy "$(getLatestTag $tagPrefix)"
    elif [ "$1" = "l" ] || [ "$1" = "list" ]; then
        list
    elif [ "$1" = "s" ] || [ "$1" = "add-script" ]; then
        if [ ! -z "$2" ]; then
            scriptExecTime="after"
            if [ ! -z "$3" ]; then
                if [ "$3" = "after" ] || [ "$3" = "before" ]; then
                    scriptExecTime="$3"
                else
                    echo "Invalid arg: $3"
                    echo "Script exec time should be either 'after' or 'before'"
                    exit
                fi
            fi
            addScript "$2" $scriptExecTime
        else
            echo "Missing path to the script"
        fi
    elif [ "$1" = "h" ] || [ "$1" = "help" ]; then
        listCommands
    else
        echo "Unrecognized command $1 below are the list of commands that can be used"
        listCommands
    fi
else
    deploy "$(getLatestTag $tagPrefix)"
fi