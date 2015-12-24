#!/bin/sh

# TODO:
#   1. BUG: get current git branch

init()
{
    local _tagPrefix=$1
    local _tagDelim=$2

    local initTagPrefix="$(git config --get gitauto.tag.prefix)"

    if [ -z "$initTagPrefix" ]; then
        config
        initTagPrefix="$(git config --get gitauto.tag.prefix)"
    fi
    local initTagDelim="$(git config --get gitauto.tag.delim)"

    local curBranch="$(git name-rev --name-only HEAD)"
    if [[ $curBranch == "release/"* ]]; then
        curBranch="release"
    elif [[ $curBranch == "feature/"* ]]; then
        curBranch="feature"
    fi

    local curBranchTagPrefix="$(git config --get gitauto.branch.$curBranch)"
    eval $_tagPrefix="'$initTagPrefix'"
    eval $_tagDelim="'$initTagDelim'"
}

config()
{
    echo
    printf "TAG Prefix for master branch? "
    read -p "[stage] " tag4Master

    printf "TAG Prefix for develop branch? "
    read -p "[qa] " tag4Develop

    printf "TAG Prefix for release branch? "
    read -p "[qa] " tag4Release

    printf "TAG Prefix for feature branch? "
    read -p "[qa] " tag4Feature
    tag4Master=${tag4Master:-stage}
    tag4Develop=${tag4Develop:-qa}
    tag4Release=${tag4Release:-qa}
    tag4Feature=${tag4Feature:-qa}

    git config gitauto.branch.master $tag4Master
    git config gitauto.branch.develop $tag4Develop
    git config gitauto.branch.release $tag4Release
    git config gitauto.branch.feature $tag4Feature
    echo "Git Auto is configured"
    echo
}

if [ -z "$1" ]; then
    init tagPrefix tagDelim
    tagIdentifier="$(date +"%y%m%d%H%M%S")"
    fullTag=$tagPrefix$tagDelim$tagIdentifier
fi
userInFullTag=$1
fullTag=${userInFullTag:-"$fullTag"}

if git rev-parse $fullTag >/dev/null 2>&1
then
    echo "TAG: $fullTag already exists. Please use a different tag"
else
    git tag $fullTag
    git push --tags
    echo "TAG: $fullTag is created and pushed remotely"
fi