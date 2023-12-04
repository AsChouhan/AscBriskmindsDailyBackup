set branchname=Commit_by_scheduaaal_%date%;
git checkout --orphan %branchname%
git add -A
git commit -m "Daily Commit"
git push AsBriskminds %branchname%