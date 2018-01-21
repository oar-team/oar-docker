#!/bin/bash
set -e

echo "Replace some oar-v2 cli by their oar-v3 equivalent"

#TODO oarwalltime oarcp oarsh oarprint oarnodechecklist oarnodecheckquery 
for oarcli in oarsub oarnodes oarstat oardel oarhold oarresume
do  
    echo "Replace $oarcli with its version 3..."
    cmd_mv="mv /usr/local/lib/oar/$oarcli /usr/local/lib/oar/$oarcli"2
    echo $cmd_mv
    $cmd_mv
    cmd_ln="ln -s /usr/local/bin/$oarcli"3" /usr/local/lib/oar/$oarcli"
    echo $cmd_ln
    $cmd_ln
done  

