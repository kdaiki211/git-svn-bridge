#!/bin/bash -eu

# Create bridge-repo and central-repo for specfied Subversion repository
SVN_REPO_URL=$1
BRIDGE_REPO_PATH=$2
GIT_REPO_PATH=$3
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUTHORS_PROG="$SCRIPT_DIR/authors_prog.py"

# Create svn-bridge and fetch
echo '*** create svn-bridge and fetch'
mkdir -p $BRIDGE_REPO_PATH
cd $BRIDGE_REPO_PATH
git svn init --prefix=svn/ $SVN_REPO_URL
git svn --authors-prog="$AUTHORS_PROG" fetch
git remote add git-central-repo $GIT_REPO_PATH

# Create git-central-repo
echo '*** create git-central-repo'
mkdir -p $GIT_REPO_PATH
cd $GIT_REPO_PATH
git init --bare
git remote add svn-bridge $BRIDGE_REPO_PATH

# Push svn-bridge to git-central-repo
echo '*** push svn-bridge to git-central-repo'
cd $BRIDGE_REPO_PATH
git push --all git-central-repo


# Add hooks/update to git-central-repo
echo '*** add hooks/update to git-central-repo'
cd $GIT_REPO_PATH
cat > hooks/update << 'EOT'
#!/bin/bash -eu
set -u
refname=$1
shaold=$2
shanew=$3

echo "shaold = $shaold"
echo "shanew = $shanew"

# we are only interested in commits to master
[[ "$refname" = "refs/heads/master" ]] || exit 0

# execute git svn dcommit first to acquire commit result to SVN
echo 'Update ref'
git update-ref HEAD $shanew
echo 'Synchronizing Subversion-repo and Git-repo...'
set +e
EOT
echo "$SCRIPT_DIR/synchronize-git-svn.sh" >> hooks/update
cat >> hooks/update << 'EOT'
SYNC_RESULT=$?
set -e
echo 'Revert ref'
git update-ref HEAD $shaold
if [ $SYNC_RESULT -ne 0 ]; then
  echo 'Updating git-central-repo to apply new SVN changes...'
EOT
echo "  $SCRIPT_DIR/synchronize-git-svn.sh" >> hooks/update
cat >> hooks/update << 'EOT'
  echo 'Updating git-central-repo done. Resolve conflict(s) and retry pushing.'
  exit 1
fi

# don't allow non-fast-forward commits
if [[ $(git merge-base "$shanew" "$shaold") != "$shaold" ]]; then
    echo "Non-fast-forward commits to master are not allowed"
    exit 1
fi
EOT
chmod 755 hooks/update


# Add hooks/post-update to git-central-repo
echo '*** add hooks/post-update to git-central-repo'
cd $GIT_REPO_PATH
cat > hooks/post-update << 'EOT'
#!/bin/bash -eu

# trigger synchronization only on commit to master
for arg in "$@"; do
    if [[ "$arg" = "refs/heads/master" ]]; then
        echo 'Updating to new commit with git-svn-id...'
EOT
echo "        $SCRIPT_DIR/synchronize-git-svn.sh GIT_HOOK" >> hooks/post-update
cat >> hooks/post-update << 'EOT'
        exit $?
    fi
done
EOT
chmod 755 hooks/post-update

