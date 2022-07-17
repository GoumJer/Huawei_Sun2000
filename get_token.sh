#!/bin/bash

mydir=`dirname $0`
myTempFile=$mydir/results.$$
myTokenFile=$mydir/last.token
source $mydir/HuaweiSolar.env
  
curl -i -s -X POST -H 'Content-Type:application/json' -d '{"userName":"$userName","systemCode":"MYPASSWORD"}'  $baseURL/login >$myTempFile

export myToken=$(cat $myTempFile|grep token|cut -d ' ' -f 2)

echo $myToken
echo $myToken > $myTokenFile
cat $myTokenFile
rm $mydir/*.$$
