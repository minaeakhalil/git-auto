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
    git config gitauto.tag.prefix $tag4Develop
    git config gitauto.tag.delim "-"
    echo "Git Auto is configured"
    echo
}

if [ -z "$1" ]; then
    init tagPrefix tagDelim
    tagIdentifier="$(date +"%y$tagDelim%m$tagDelim%d$tagDelim%H$tagDelim%M$tagDelim%S")"
    fullTag=$tagPrefix$tagDelim$tagIdentifier
fi
userInFullTag=$1
fullTag=${userInFullTag:-"$fullTag"}

if [ ! -z "$(git rev-parse $fullTag >/dev/null 2>&1)" ]; then
    echo "TAG: $fullTag already exists. Please use a different tag"
else
    curCommitHash="$(git rev-parse --verify HEAD)"
    commit=${curCommitHash:0:7}
    tagFound="$(git show-ref --tags -d | grep ^$curCommitHash | sed -e 's,.* refs/tags/,,' -e 's/\^{}//')"
    if [ ! -z "$tagFound" ]; then
        echo "Commit ($commit) is already tagged with ($tagFound)"
        echo "New tag was NOT created"
    else
        git tag $fullTag
        git push --tags
        echo "New TAG: $fullTag is created for commit ($commit) and pushed remotely"
    fi
fi