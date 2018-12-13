#!/bin/bash -eu

SCRIPT_DIR=$(cd $(dirname $0); pwd)
source $SCRIPT_DIR/conf_util.sh

# SVN_CONFIG_CONF=~/.subversion/config
SVN_SERVER_CONF=~/.subversion/servers

# set servers
set_conf_value $SVN_SERVER_CONF 'store-plaintext-passwords' 'yes'

