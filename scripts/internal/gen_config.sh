#!/bin/bash -eu

BRIDGE_REPO_PATH=$1
SCRIPT_PATH=$(cd $(dirname $0)/..; pwd)

echo "REPOS=(\"$BRIDGE_REPO_PATH\")" >> $SCRIPT_PATH/synchronize-git-svn.sh.config
