#! /usr/bin/env awk -f
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Copyright © 2011, Damian Carrillo
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, 
#   this list of conditions and the following disclaimer in the documentation 
#   and/or other materials provided with the distribution.
# * Neither the name of the <organization> nor the names of its contributors 
#   may be used to endorse or promote products derived from this software 
#   without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY 
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# template.awk
# 
# 2011-10-08
# 
# Usage:
#   $ ./template.awk -v outputDir=./some/dir .../path/to/some/file.template
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BEGIN {
    if (!outputDir) {
        outputDir = "./"
    }

    split(ARGV[1], components, "\/")
    
    outputFile = components[length(components)]
    
    if (!index(outputFile, ".template")) {
        exitWithErrorMessage("Invalid template file - expected filename " \
            "with .template suffix")
    }
    
    # strip .template suffix
    sub(/\.template/, "", outputFile)
    
    tempoutputFilePath = "/tmp/" outputFile
    outputFilePath = outputDir "/" outputFile
    
    includeDir = ""
    
    for (i = 1; i < length(components); i++) {
        includeDir = includeDir components[i] "/"
    }
}
{
    if ($0 ~ /\@include-fragment/) {
        line = $0
    
        sub(/.*@include-fragment/, "", line)
        split(line, arguments)
        
        if (length(arguments) < 2) {
            errorMessage = "Unable to parse @include statement on line " \
                NR ".  Expected \"#include-fragment file fragment\", " \
                "got \"" line "\"."
                
            exitWithErrorMessage(errorMessage)
        }

        location = index(line, "#")
        whitespace = ""

        for (i = 0; i < location - 1; i++) {
            whitespace = whitespace " "
        }
        
        fragmentFile = includeDir arguments[1]
        fragmentLabel = arguments[2]
        
        includeFragment(whitespace, fragmentFile, fragmentLabel)
    }
    else {
        print > tempoutputFilePath
    }
}
END {
    while ((getline line < tempoutputFilePath) > 0) {
        print line > outputFilePath
    }
    close(tempoutputFilePath)
}

function includeFragment(linePrefix, fragmentFile, fragmentLabel) {
    while ((getline line < fragmentFile) > 0) {
        if (line ~ "@start-fragment " fragmentLabel) {
            while ((getline line < fragmentFile) > 0) {
                if (line ~ "@end-fragment " fragmentLabel) {
                    close(fragmentFile)
                    return
                }
                print line > tempoutputFilePath
            }
        }
    }
    
    exitWithErrorMessage("Unable to find fragment with label \"" \
        fragmentLabel "\" in " fragmentFile)
}

function exitWithErrorMessage(errorMessage) {        
    system("echo 'Error: " errorMessage "' 1>&2")
    exit 1
}