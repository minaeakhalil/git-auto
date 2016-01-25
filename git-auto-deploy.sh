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
    local _tagPrefix=$1
    local _deployStatus=$2
    local fetchStatus=''
    local pullStatus=''
    local tagsStatus=''
    local exitStatus=0

    local initTagPrefix="$(git config --get gitauto.deploy.prefix)"

    fetchStatus="$(git fetch --all 2>&1)"
    exitStatus=$?
    if [ $exitStatus -eq 0 ]; then
        pullStatus="$(git pull 2>&1)"
        exitStatus=$?
        if [ $exitStatus -eq 0 ]; then
            tagsStatus="$(git pull --tags 2>&1)"
            exitStatus=$?
            if [ $exitStatus -eq 0 ]; then
                echo "Fetching and Pulling from remote repo DONE"
            else
                echo "Err while pulling tags from remote repo"
                echo $tagsStatus
                return $exitStatus
            fi
        else
            echo "Err while pulling from remote repo"
            echo $pullStatus
            return $exitStatus
        fi
    else
        echo "Err while fetching from remote repo"
        echo $fetchStatus
        return $exitStatus
    fi

    if [ -z "$initTagPrefix" ]; then
        config
        initTagPrefix="$(git config --get gitauto.deploy.prefix)"
    fi

    deployStatus="$(git config --get gitauto.deploy.status)"

    eval $_tagPrefix="'$initTagPrefix'"
    eval $_deployStatus="'$deployStatus'"

    return $exitStatus
}

addScript()
{
    git config gitauto.deploy.script-"$2" "$1"
    echo "Your script '$1' is added and scheduled to be executed $2 deployment"
}

list()
{
    git tag -l
}

pause()
{
    local exitStatus=0

    git config gitauto.deploy.status 'pause'
    exitStatus=$?
    if [ $exitStatus -eq 0 ]; then
        echo "Code deployment is now PAUSED"
    else
        echo "There were an issue while pausing code deployment, please try again later"
    fi

    return $exitStatus
}

resume()
{
    local exitStatus=0

    git config gitauto.deploy.status 'deploy'
    exitStatus=$?
    if [ $exitStatus -eq 0 ]; then
        echo "Code deployment is now RESUMED"
    else
        echo "There were an issue while resuming code deployment, please try again later"
    fi

    return $exitStatus
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
    eval $_result="'$scriptResult'"
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
        execScript result "before" "$scriptBefore"
        exitStatus=$?
        if [ $exitStatus -gt 0 ]; then
            retStatus=$exitStatus
            printf "FAILED, Err: $result\n"
        else
            printf "SUCCESSED\n"
        fi
    fi

    printf "Code Deployment using GIT TAG ($1): "
    if [ $exitStatus -eq 0 ]; then
        deployResult=$(git checkout "$1" 2>&1)
        exitStatus=$?
        if [ $exitStatus -gt 0 ]; then
            retStatus=$exitStatus
            printf " FAILED, Err: $deployResult\n"
        else
            printf " SUCCESSED\n"
        fi
    else
        printf "STOPPED\n"
    fi

    if [ ! -z "$scriptAfter" ]; then
        printf "Post-Deployment Script: "
        if [ $exitStatus -eq 0 ]; then
            execScript result "after" "$scriptAfter"
            exitStatus=$?
            if [ $exitStatus -gt 0 ]; then
                retStatus=$exitStatus
                printf "FAILED, Err: $result\n"
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

tagsList=($(git tag -l))

init tagPrefix deployStatus
exitStatus=$?
if [ $exitStatus -eq 0 ]; then
    if [ ! -z "$1" ]; then
        if [ "$1" = "d" ] || [ "$1" = "deploy" ]; then
            if [ $deployStatus = "deploy" ]; then
                deploy "$(getLatestTag $tagPrefix)"
            else
                echo "Code Deployment is current PAUSED"
                echo "try (git-auto-deploy resume) to resume code deployment"
            fi
        elif [ "$1" = "p" ] || [ "$1" = "pause" ]; then
            pause
        elif [ "$1" = "r" ] || [ "$1" = "resume" ]; then
            resume
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
                echo "No script provided"
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
else
    echo "Cannot deploy code without pulling from remote repo first"
    exit $exitStatus
fi
exit 0