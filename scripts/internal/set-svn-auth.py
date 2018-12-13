#!/usr/bin/python
import sys
import re
import subprocess
import os

script_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(script_dir)
import user_info_loader

argc = len(sys.argv)
if argc != 3:
  print("invalid argument")
  print("usage: " + sys.argv[0] + " git-email svn-url")
  print("This script execute 'svn info svn-url' command to store the password in plaintext corresponding to git-email")
  exit(-1)
git_email = sys.argv[1]
svn_url = sys.argv[2]

with open(user_info_loader.user_info, "r") as f:
  while True:
    line = f.readline()
    if not line:
      break
    m = re.match('^.*:' + git_email + ':(.*):(.*)$', line)
    if m:
      svn_user = m.group(1)
      svn_password = m.group(2)

      cmd = 'svn info --non-interactive --username=' + svn_user + ' --password=' + svn_password + ' ' + svn_url
      ret = subprocess.call(cmd, shell=True)

      if ret != 0:
        sys.stderr.write('Storing password failed. Is svn-url "' + svn_url + '" is valid URL?\n')
        exit(ret)
      else:
        exit(0)
sys.stderr.write('git-email "' + git_email + '" not found.\n')
exit(1)
