#!/bin/bash -eu

if [ $# -ne 1 ]; then
  echo "Usage: $0 SVN_URL"
  exit 1
fi
SVN_REPO_URL=$1

TOP_DIR=$(cd $(dirname $0)/..; pwd)
SCRIPT_DIR=$TOP_DIR/scripts
REPO_PATH="$TOP_DIR/repo"
WORK_PATH="$TOP_DIR/work"
BRIDGE_REPO_PATH="$REPO_PATH/bridge"
GIT_REPO_PATH="$REPO_PATH/git"
GIT_WORK_PATH="$WORK_PATH/git"
SVN_WORK_PATH="$WORK_PATH/svn" # for testing

echo '*** configure svn'
$SCRIPT_DIR/internal/configure_svn.sh

echo '*** create repository/work path'
mkdir -p $REPO_PATH
mkdir -p $WORK_PATH

echo '*** check git config'
$SCRIPT_DIR/internal/set-svn-auth.py `git config --global user.email` $SVN_REPO_URL
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo 'set valid email address to git config that also exists in user_info.txt.'
  exit 1
fi

echo '*** create git bridge & central repo'
$SCRIPT_DIR/internal/create_git_repo_from_svn_repo.sh $SVN_REPO_URL $BRIDGE_REPO_PATH $GIT_REPO_PATH

echo '*** generate config file for synchronization script'
$SCRIPT_DIR/internal/gen_config.sh $BRIDGE_REPO_PATH

echo '*** setup cron for svn-to-git synchronization'
CRON_NEW_LINE=`crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_DIR/internal/synchronize-git-svn.sh"`
# awk is used for removing duplicate lines (https://stackoverflow.com/a/11532197/1855161)
echo "$CRON_NEW_LINE" | awk '!x[$0]++' | crontab -

echo '*** first synchronization'
$SCRIPT_DIR/internal/synchronize-git-svn.sh

echo 'Setup successfully'
