#!/bin/sh
cd "E:\Battle.net\World of Warcraft\_retail_"
git checkout master
git add .
git commit -am "Nightly Update"
git push -f WoWUI master