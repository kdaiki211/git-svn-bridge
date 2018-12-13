#!/bin/bash -ex

TOP_DIR=$(cd $(dirname $0); pwd)/..
TEST_DIR=$TOP_DIR/test
REPO_PATH=$TOP_DIR/repo
WORK_PATH=$TOP_DIR/work
SCRIPT_DIR=$TOP_DIR/scripts
SVN_REPO_PATH=$1
SVN_REPO_URL="svn://localhost/$SVN_REPO_PATH"
SVN_WORK_PATH=$WORK_PATH/svn

SAMPLE_FILENAME1=hoge.c
SAMPLE_FILENAME2=fooooo.c

if [ $# -ne 1 ]; then
  echo "Usage: $0 SVN_REPO_PATH_TO_CREATE"
  exit 1
fi

$SCRIPT_DIR/internal/configure_svn.sh
mkdir -p $REPO_PATH
$TEST_DIR/create_svn_repo.sh $SVN_REPO_PATH $SVN_REPO_URL

# commit a file for testing (author = git global user)
echo '*** commit something'
python $SCRIPT_DIR/internal/set-svn-auth.py `git config --global user.email` $SVN_REPO_URL
svn checkout $SVN_REPO_URL $SVN_WORK_PATH
echo 'sample file' > $SVN_WORK_PATH/$SAMPLE_FILENAME1
svn add $SVN_WORK_PATH/$SAMPLE_FILENAME1
svn commit -m 'svn commit for testing' $SVN_WORK_PATH

# commit a file for testing (author = unknown user (not listed in user_info.txt)
svn info --non-interactive --username='i_dont_like_git' --password='i_like_svn' $SVN_REPO_URL
echo 'hogehoge' > $SVN_WORK_PATH/$SAMPLE_FILENAME2
svn add $SVN_WORK_PATH/$SAMPLE_FILENAME2
svn commit -m 'svn commit for testing by svn-only user' $SVN_WORK_PATH
