#!/usr/bin/env python

import os
import sys
import re
import shutil
import subprocess
import hashlib

from pygithub3 import Github

gh_user = "rondiplomatico"
gh_org = "OpenCMISS-examples"
gh = Github(login=gh_user, password='')

example_repos = gh.repos.list_by_org(gh_org)

# Old repo removal script for mistakeably added ones
#re_rem = re.compile(r"^(build_x86|examples_|manage_build).*", re.MULTILINE)
#for repo in example_repos.all():
#    if re_rem.search(repo.name):
        #print(m)
#        print("Removing GitHub repo {}".format(repo.name))
#        gh.repos.delete(gh_org, repo.name)
#exit()

f = lambda repo: [repo.name, repo]
existing = dict(map(f,example_repos.all()))

def getRepoDict(reponame,desc):
    return dict(name=reponame, has_wiki=0, has_issues=0,
                description="OpenCMISS example repository for {}".format(desc))
def run(cmd, wd=os.getcwd()):
    print("Running {} in {}".format(cmd,wd))
    #return os.system(cmd)
    
created = []
rootDir = os.getcwd()
template = os.path.join(rootDir, "CMakeLists.template.cmake")
for dirName, subdirList, fileList in os.walk(rootDir):
    if dirName != rootDir:  # and not re.match(".*build.*",dirName):
        for file in fileList:
            if file == 'CMakeLists.txt':
                fullname = dirName.lower().replace(rootDir, "").replace("/", "_")[1:]
                
                # Short the names
                short = fullname
                print "\nProcessing {}".format(fullname)
                if len(fullname) > 90:
                    short = fullname[:90]+"_"+hashlib.sha224(fullname).hexdigest()[:5]
                
                wd = os.path.join(rootDir,dirName)
                if not short in existing:
                    print "Creating GitHub repo {} ({})".format(short,fullname)
                    #repo = gh.repos.create(getRepoDict(short,fullname),gh_org)
                else:
                    print "Getting existing repo " + short
                    repo = existing[short]
                    
                os.chdir(wd)
                msg = "Update. Automated python script commit."    
                if not os.path.exists(os.path.join(wd,".git")):
                    run("git init .",wd)
                    run("git checkout --orphan devel",wd)
                    url = repo.html_url.replace("https://github.com/","git@github.com:")
                    run("git remote add origin {}".format(url),wd)
                    msg = "Initial commit of example"
                 
                    run("git add .",wd)
                    run('git commit -a -m "{}"'.format(msg),wd)
                    run('git push origin devel -u',wd)
    
                    # Add created repo as submodule
                    os.chdir(rootDir)
                    reldir = dirName.replace(rootDir, "")[1:]
                    run("git rm -rf {} --cached".format(reldir),rootDir)
                    run("git submodule add {} {}".format(repo.html_url,reldir),rootDir)
                    continue



