#!/bin/bash -eu

TOP_PATH=$(cd $(dirname $0)/..; pwd)
TEST_PATH=$TOP_PATH/test
SCRIPT_PATH=$TOP_PATH/scripts

REPO_PATH=$TOP_PATH/repo
SVN_REPO_PATH=$REPO_PATH/svn
SVN_REPO_URL=svn://localhost$SVN_REPO_PATH
GIT_REPO_PATH=$REPO_PATH/git

WORK_PATH=$TOP_PATH/work
SVN_WORK_PATH=$WORK_PATH/svn
GIT_WORK_PATH=$WORK_PATH/git


############################
# PREPARE TESTING
############################

# clean up repositories & working (copy|directory)
$SCRIPT_PATH/internal/clean.sh $REPO_PATH $WORK_PATH

# create sample Subversion repository
$TEST_PATH/create_sample_repo.sh $SVN_REPO_PATH

# setup bridge & central repos
$SCRIPT_PATH/setup.sh $SVN_REPO_URL


############################
# TEST MAIN
############################

SAMPLE_FILENAME1=hoge.c # commited from SVN (from create_sample_repo.sh)
SAMPLE_FILENAME2=piyo.c
SAMPLE_FILENAME3=foobar.c
SAMPLE_FILENAME4=jp1.c
SAMPLE_FILENAME5=jp2.c

# clone git repo
echo '*** cloning git-repo'
git clone $GIT_REPO_PATH $GIT_WORK_PATH

# check git and svn have same file
echo '*** verifying svn-repo and git-repo'
diff $SVN_WORK_PATH/$SAMPLE_FILENAME1 $GIT_WORK_PATH/$SAMPLE_FILENAME1

# [Scenario] SVN has changed, then git push occured. Each files are not conflicted.
echo '*** test svn commit then git push without conflict'
pushd $SVN_WORK_PATH
echo 'Hello SVN' >> $SAMPLE_FILENAME1
$SCRIPT_PATH/internal/set-svn-auth.py 'hanako.yamada@XXXXXXXXXXX.com' $SVN_REPO_URL
svn commit -m 'add Hello SVN comment.'
popd
pushd $GIT_WORK_PATH
echo 'This is non-conflicted file' >> $SAMPLE_FILENAME2
git add $SAMPLE_FILENAME2
git config --local user.name 'Hanako Yamada'
git config --local user.email 'hanako.yamada@XXXXXXXXXXX.com'
git commit -m "add $SAMPLE_FILENAME2 from GIT"

echo 'foobar file' >> $SAMPLE_FILENAME3
git add $SAMPLE_FILENAME3
git commit -m "add $SAMPLE_FILENAME3 from GIT"
set +e
git push # sync & dcommit. push result will be success only when dcommit success.
PUSH_RESULT=$?
set -e
# expected "success" exit code
if [ $PUSH_RESULT -ne 0 ]; then
  echo 'FATAL: Exit code of git push must be success (zero).'
  exit 1
fi
git pull --no-edit # update for next test
echo '*** test succeeded!'
popd


# [Scenario] Test japanese SVN comment
echo '*** test japanese SVN comment'
pushd $SVN_WORK_PATH
echo 'こんにちは SVN' > $SAMPLE_FILENAME4
svn add $SAMPLE_FILENAME4
$SCRIPT_PATH/internal/set-svn-auth.py 'hanako.yamada@XXXXXXXXXXX.com' $SVN_REPO_URL
svn commit -m '日本語コメントテスト (SVN 側)'
popd
pushd $GIT_WORK_PATH
echo 'こんにちは GIT' >> $SAMPLE_FILENAME5
git add $SAMPLE_FILENAME5
git config --local user.name 'Hanako Yamada'
git config --local user.email 'hanako.yamada@XXXXXXXXXXX.com'
git commit -m 'こんにちは GIT'

set +e
git push # sync & dcommit. push result will be success only when dcommit success.
PUSH_RESULT=$?
set -e
# expected "success" exit code
if [ $PUSH_RESULT -ne 0 ]; then
  echo 'FATAL: Exit code of git push must be success (zero).'
  exit 1
fi
git pull --no-edit # update for next test
echo '*** test succeeded!'
popd


# [Scenario] SVN has changed, then occured sync by cron, then git push. Each files are not conflicted.
echo '*** test svn commit and sync then git push without conflict'
pushd $SVN_WORK_PATH
echo 'Second change' >> $SAMPLE_FILENAME1
$SCRIPT_PATH/internal/set-svn-auth.py 'taro.yamada@XXXXXXXXXXX.com' $SVN_REPO_URL
svn commit -m 'add Hello SVN comment'
popd

pushd $SCRIPT_PATH
$SCRIPT_PATH/internal/synchronize-git-svn.sh # called from cron by all rights
popd

pushd $GIT_WORK_PATH
git pull --no-edit
echo 'barbar' >> $SAMPLE_FILENAME2
git add $SAMPLE_FILENAME2
git config --local user.name 'Taro Yamada'
git config --local user.email 'taro.yamada@XXXXXXXXXXX.com'
git commit -m 'update bar.c from GIT'

set +e
git push # sync & dcommit. push result will be success only when dcommit success.
PUSH_RESULT=$?
set -e
# expected "success" exit code
if [ $PUSH_RESULT -ne 0 ]; then
  echo 'FATAL: Exit code of git push must be success (zero) when retry pushing.'
  exit 1
fi
git pull --no-edit # update for next test
echo '*** test succeeded!'
popd


# [Scenario] Conflict
echo '*** test conflict situation (svn commit then git push)'
pushd $SVN_WORK_PATH
svn update
echo 'Good afternoon SVN' >> $SAMPLE_FILENAME1
$SCRIPT_PATH/internal/set-svn-auth.py 'taro.yamada@XXXXXXXXXXX.com' $SVN_REPO_URL
svn commit -m 'add Good afternoon SVN comment'
popd

pushd $GIT_WORK_PATH
echo 'Good afternoon GIT' >> $SAMPLE_FILENAME1
git add $SAMPLE_FILENAME1
git config --local user.name 'Taro Yamada'
git config --local user.email 'taro.yamada@XXXXXXXXXXX.com'
git commit -m 'add Good afternoon GIT comment'
set +e
git push
PUSH_RESULT=$?
set -e
if [ $PUSH_RESULT -eq 0 ]; then
  echo 'FATAL: Exit code of git push must be fail (non-zero) in conflict situation, but git push was succeeded unexpectedly.'
  exit 1
fi

pushd $GIT_WORK_PATH
set +e
git pull --no-edit
PULL_RESULT=$?
set -e
if [ $PULL_RESULT -eq 0 ]; then
  echo 'FATAL: Conflict expected, but exit code is success. this behavior is unexpected.'
  exit 1
fi

sed -i.bak -e '/[<>=]\{7\}/d' -e '/Good afternoon GIT/d' -e 's/Good afternoon SVN/Good afternoon SVN and GIT/' $SAMPLE_FILENAME1
rm $SAMPLE_FILENAME1.bak
git add $SAMPLE_FILENAME1
echo '[DEBUG] EXECUTE git commit'
# git merge --continue -m 'fix conflict'
git commit -m 'fix conflict!'
echo '[DEBUG] DONE git commit'
git config --local user.name 'Daiki Komatsuda'
git config --local user.email 'kdaiki211@gmail.com'
set +e
git push
PUSH_RESULT=$?
set -e
if [ $PUSH_RESULT -ne 0 ]; then
  echo 'FATAL: Exit code of git push must be success (zero) in conflict-resolved situation, but git push was failed unexpectedly.'
  exit 1
fi
git pull --no-edit # merge new commit with git-svn-id
popd

# [Scenario] Merge another branch
pushd $GIT_WORK_PATH
git checkout -b new_feature
echo "this is a code for new feature" >> $SAMPLE_FILENAME1
git add $SAMPLE_FILENAME1
git commit -m "developing new feature"

git checkout master
echo "bugfix" >> $SAMPLE_FILENAME2
git add $SAMPLE_FILENAME2
git commit -m "bugfix"

git merge --no-edit --no-ff -m 'merge new feature' new_feature
git push

git branch --delete new_feature

echo '*** test succeeded!'
popd


echo 'ALL TEST PASSED!'
