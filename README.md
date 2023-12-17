Installation to non-empty directory, post WoW install:  

git init  
git remote add origin https://github.com/jon-skocik/WoWUI.git  
git fetch  
git reset origin/master  # this is required if files in the non-empty directory are in the repo  
git checkout -t origin/master  
