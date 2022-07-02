#!/bin/bash
#

##############
#
# FUNCTIONS
#
##############

# Process parameters
#####################################
CheckParameters () {
 myFunction=$1
 myDebug=$2
}

# Set enviroment
#####################################
setEnvironment () {
  mydir=`dirname $0`
  myTempFile=$mydir/results.$$
  myTokenFile=$mydir/last.token
  source $mydir/HuaweiSolar.env
}

# Debug info
#####################################
Echo () {
 if [[ "$myDebug" == "Y" ]]; then
    echo $1 $2 $3 $4 $5
 fi
}

# Check token validity
#####################################
CheckToken () {
  myURL="$myDomoticzURL/json.htm?type=command&param=getuservariable&idx=$myDomoticzHuaweiTokenTimeStampID"
  wget -qO $myTempFile $myURL

  myTokenEpoch=$(cat $myTempFile|jq '.result[].Value'|tr -d '"')
  myEpoch=$EPOCHSECONDS
  myTokenAge=$(echo $(( myEpoch - myTokenEpoch )))

  Echo myTokenAge: $myTokenAge seconds
  if [ $myTokenAge -gt 1500 ]
    then
    Echo "-----"
    Echo "Username: "$userName
    Echo "SystemCode: "$systemCode
    Echo "Token is > 25 minutes old, refresh required"
    Echo "-----"
    $mydir/get_token.sh
    myToken=$(cat $myTokenFile)
    Echo "New token: "$myToken
    if [[ ! $myToken ]];
      then
      Echo "No token available"
      exit
    fi
    echo $myToken >$myTokenFile
    # Write new timestamp to Domoticz
    curl "$myDomoticzURL/json.htm?type=command&param=updateuservariable&vname=$myDomoticzHuaweiTokenTimeStampName&vtype=2&vvalue=$myEpoch"
  else
    # Token is valid, retreive value from domoticz
    myToken=$(cat $myTokenFile)
    Echo "Existing token: "$myToken
  fi
}

# Build Request header
###########################
BuildHeader () {
  myEpoch=$(echo $(date +%s%3N))
  myHeaderData="{\"stationCodes\": \"$stationCode\",\"collectTime\": \"$myEpoch\"}"
  Echo "Data: "$myHeaderData
}

# Get real time statistics
###########################
RealTime () {
  Echo ======
  Echo "Existing token: "$myToken
  Echo "StationCode: "$stationCode

  curl -s -X POST -H "CONTENT-Type:application/json"  -H "XSRF-TOKEN:$myToken" -d "$myHeaderData"  $baseURL/getStationRealKpi > $mydir/realtime.$$

  myToday=$(cat $mydir/realtime.$$ |jq '.data[]|."dataItemMap".day_power'|bc)
  myThisMonth=$(cat $mydir/realtime.$$ |jq '.data[]|."dataItemMap".month_power'|bc)
  curl "$myDomoticzURL/json.htm?type=command&param=udevice&idx=$DomoticzHuaweiGeneratedToday&nvalue=0&svalue=$myToday"
  curl "$myDomoticzURL/json.htm?type=command&param=udevice&idx=$DomoticzHuaweiGeneratedThisMonth&nvalue=0&svalue=$myThisMonth"
}

# Get Hourly statistics
###########################
Hourly () {
  Echo ======
  Echo "Existing token: "$myToken
  Echo "Header: "$myHeaderData

  curl -s -X POST -H "CONTENT-Type:application/json"  -H "XSRF-TOKEN:$myToken" -d "$myHeaderData"  $baseURL/getKpiStationHour > $mydir/hourly.$$
  cat $mydir/hourly.$$ |jq -r '.data[]|[.collectTime, .dataItemMap.inverter_power]|@csv' > $mydir/hourly_tmp.$$
  while read myLine; do
      myTimeStamp=$(echo $myLine|cut -d, -f1)
      myValue=$(echo $myLine|cut -d, -f2)
      if [ -z $myValue ]
      then
        Echo "myValue is leeg"
        myValue=0
      fi
      Echo $myTimeStamp, $myValue
      WriteInflux hour $myValue $myTimeStamp
  done < $mydir/hourly_tmp.$$
  Echo ---
}

# Get Daily statistics
###########################
Daily () {
  Echo ======
  Echo "Existing token: "$myToken
  Echo "Header: "$myHeaderData

  curl -s -X POST -H "CONTENT-Type:application/json"  -H "XSRF-TOKEN:$myToken" -d "$myHeaderData"  $baseURL/getKpiStationDay > $mydir/daily.$$
  cat $mydir/daily.$$ |jq -r '.data[]|[.collectTime, .dataItemMap.inverter_power]|@csv' > $mydir/daily_tmp.$$
  while read myLine; do
      myTimeStamp=$(echo $myLine|cut -d, -f1)
      myValue=$(echo $myLine|cut -d, -f2)
      if [ -z $myValue ]
      then
        Echo "myValue is leeg"
        myValue=0
      fi
      Echo $myTimeStamp, $myValue
      WriteInflux day $myValue $myTimeStamp
  done < $mydir/daily_tmp.$$
  Echo ---
}


# Get Yearly statistics
###########################
Yearly () {
  Echo ======
  Echo "Existing token: "$myToken
  Echo "Header: "$myHeaderData

  curl -s -X POST -H "CONTENT-Type:application/json"  -H "XSRF-TOKEN:$myToken" -d "$myHeaderData"  $baseURL/getKpiStationYear > $mydir/yearly.$$
  cat $mydir/yearly.$$ |jq -r '.data[]|[.collectTime, .dataItemMap.inverter_power]|@csv' > $mydir/yearly_tmp.$$
  while read myLine; do
      myTimeStamp=$(echo $myLine|cut -d, -f1)
      myValue=$(echo $myLine|cut -d, -f2)
      if [ -z $myValue ]
      then
        Echo "myValue is leeg"
        myValue=0
      fi
      Echo $myTimeStamp, $myValue
      WriteInflux year $myValue $myTimeStamp
  done < $mydir/yearly_tmp.$$
  Echo ---
}

# Write data to influx database
###############################
WriteInflux () {
  # $1=periodicity
  # $2=value
  # $3=timestamp
  Echo Influx write: $1, $2, $3
  influx -username $myInfluxUser -password $myInfluxPass -host $myInfluxHost -database $myInfluxDB -precision=ms -execute "insert $1 value=$2 $3"
}

# Clean up tempfiles etc.
#####################################
CleanUp () {
  if [[ "$myDebug" != "Y" ]]; then
    rm $mydir/*.$$
  fi
}

######################
#
# Program starts here
#
#####################
CheckParameters $1 $2 $3
setEnvironment
CheckToken
BuildHeader

case $1 in
  RealTime)
    RealTime
    ;;
  Hour)
    Hourly
    ;;
  Day)
    Daily
    ;;
  Year)
    Yearly
    ;;
  *)
    echo "Unknowm parameter (RealTime, Hour, Day, Year)"
    echo "Exiting"
    ;;
esac

CleanUp
