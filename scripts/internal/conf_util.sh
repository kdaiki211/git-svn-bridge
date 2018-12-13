#!/bin/bash -eu

function set_conf_value() {
  FILE_NAME=$1
  VAR_NAME=$2
  VAR_VALUE=$3
  if [ -e $FILE_NAME ]; then
    SED_PATTERN='s/^[ 	]*#*[ 	]*'$VAR_NAME'[ 	]*=.*/'$VAR_NAME' = '$VAR_VALUE'/g'
    GREP_PATTERN='[^#]*'$VAR_NAME'\s*=\s*'$VAR_VALUE'\s*'
    # echo 'SED_PATTERN = '$SED_PATTERN
    # echo 'GREP_PATTERN = '$GREP_PATTERN
    sed -i.bak -e "$SED_PATTERN" $FILE_NAME
    grep -e "$GREP_PATTERN" $FILE_NAME
  else
    exit 1
  fi
}
