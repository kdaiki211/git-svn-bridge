#!/bin/bash -eu

TOP_DIR=$(cd $(dirname $0); pwd)/..
SCRIPT_DIR=$TOP_DIR/scripts
source $SCRIPT_DIR/internal/conf_util.sh

SVN_REPO_PATH=$1
SVN_REPO_URL=$2
SVN_CONFIG_DIR=$SVN_REPO_PATH/conf
SVN_SVNSERVE_CONF=$SVN_CONFIG_DIR/svnserve.conf

# create sample svn repo for testing
svnadmin create $SVN_REPO_PATH

# set svnserve.conf for testing
set_conf_value $SVN_SVNSERVE_CONF 'anon-access' 'none'
set_conf_value $SVN_SVNSERVE_CONF 'auth-access' 'write'
set_conf_value $SVN_SVNSERVE_CONF 'password-db' 'passwd'

# add passwd for authentication testing
cat << EOT > $SVN_REPO_PATH/conf/passwd
[users]
taro = taro_password
hanako = hanako_password
kdaiki211 = kdaiki211_password
i_dont_like_git = i_like_svn
EOT

# start svn server
if ! pgrep svnserve; then
  svnserve -d
fi
