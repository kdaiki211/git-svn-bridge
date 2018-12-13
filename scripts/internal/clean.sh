#!/bin/bash -eu

SCRIPT_DIR=$(cd $(dirname $0); pwd)/..
REPO_PATH=$1
WORK_PATH=$2

echo 'warning: this script cleans all previous repository. press enter to continue.'
read
cd $SCRIPT_DIR
rm -rf $REPO_PATH $WORK_PATH __pycache__
rm -f *.pyc synchronize-git-svn.sh.log* synchronize-git-svn.sh.config
