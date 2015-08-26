#!/usr/bin/env python

import os
import sys
import shutil

rootDir = os.getcwd()
template = os.path.join(rootDir, "CMakeLists.template.cmake")
for dirName, subdirList, fileList in os.walk(rootDir):
    if dirName != rootDir:
        for file in fileList:
            if file == 'Makefile':
                print "Creating CMakeLists.txt in " + dirName
                shutil.copy(template, os.path.join(dirName, "CMakeLists.txt"))
                continue
