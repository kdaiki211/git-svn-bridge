This project is forked from mrts/git-svn-bridge. Ported scripts in C# to Python3.

TODO: write up README.md completely

---

# Setup

1. Set `user.name` and `user.email` using `git config --global` command on your git-svn-bridge server.
1. Add your subversion username and password corresponding to your git account in script/user_info.txt (TODO: fix saving password in plaintext)

# Test

Use test/run_test.sh.
Before you execute it, run `svnserve` to create sample svn-repo from the test script.

# Prepare bridge-repo and git-repo

1. Run scripts/setup.sh to create bridge-repo and git-repo from svn-repo you specified.

Now you can `git clone` from repo/git using your favorite transport protocol (SSH for example) .
