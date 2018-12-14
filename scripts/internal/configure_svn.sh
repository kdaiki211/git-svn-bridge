#!/bin/bash -eux

SCRIPT_DIR=$(cd $(dirname $0); pwd)
source $SCRIPT_DIR/conf_util.sh

# SVN_CONFIG_CONF=~/.subversion/config
SVN_SERVER_CONF=~/.subversion/servers

if ! [ -e $SVN_SERVER_CONF ]; then
    echo "file not found: $SVN_SERVER_CONF"
    echo "generating $SVN_SERVER_CONF with svn command..."
    svn help
    if ! [ -e $SVN_SERVER_CONF ]; then
        echo "failed to create $SVN_SERVER_CONF..."
        exit 1
    fi
fi

# set servers
set_conf_value $SVN_SERVER_CONF 'store-plaintext-passwords' 'yes'

