#!/usr/bin/python
import sys
import re

import user_info_loader

argc = len(sys.argv)
if argc != 2:
  print("invalid argument")
  print("usage: " + sys.argv[0] + " svn-user")
  print("This script returns authors-prog corresponding to svn-uesr. If not found, returns \"svn-user <>\"")
  exit(-1)
svn_user = sys.argv[1]

with open(user_info_loader.user_info, "r") as f:
  while True:
    line = f.readline()
    if not line:
      break
    m = re.match('^(.*):(.*):' + svn_user + ':.*$', line)
    if m:
      git_name = m.group(1)
      git_email = m.group(2)

      author = git_name + ' <' + git_email + '>'
      print(author)
      exit(0)
print(svn_user + ' <>')
