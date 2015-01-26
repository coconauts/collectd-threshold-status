#!/bin/bash

# Comments
<<COMMENT1
This script will read from collectd log in syslog

  [2014-11-20 06:26:44] Notification: severity = FAILURE, host = vpn, plugin = cpu, plugin_instance = 0, type = cpu, type_instance = user, message = Host vpn, plugin cpu (instance 0) type cpu (instance user): Data source "value" is currently 99.432869. That is above the failure threshold of 50.000000.
  [2014-11-20 06:28:54] Notification: severity = OKAY, host = vpn, plugin = cpu, plugin_instance = 0, type = cpu, type_instance = user, message = Host vpn, plugin cpu (instance 0) type cpu (instance user): All data sources are within range again.

and will generate a json file with the current status of the servers, eg:

  {"servers":[
  {"name":"apps", "status":"OK","message":"Host apps, plugin cpu (instance 0) type cpu (instance user): All data sources are within range again.","timestamp":"2014-12-16 06:26:40","type":"cpu"}
  ,{"name":"ci", "status":"OK","message":"","timestamp":"","type":""}
  ,{"name":"collectd", "status":"OK","message":"","timestamp":"","type":""}
  ]}
COMMENT1

# Config
servers_folder='/var/lib/collectd/rrd/'
lines=60 #Lines to tail the collectd log
status_output='./status.out'
status_json='./status.json'

# Do not touch
servers=`command ls -1 $servers_folder`
notifications=`tail -n $lines  /var/log/collectd.log | grep "Notification"`

echo "Running collectd threshold status script at `date`"

oldStatus=`cat $status_output`
echo "{\"servers\":[" > $status_json 
echo "" > $status_output #Clean status output file

separator=""
for server in `command ls -1 $servers_folder`; do
  
  old_line=`echo "$oldStatus" | grep "^$server;"`
    
  old_status=`echo $old_line | cut -d';' -f2`
  old_timestamp=`echo $old_line | cut -d';' -f3`
  old_type=`echo $old_line | cut -d';' -f4`
  old_message=`echo $old_line | cut -d';' -f5`
  
  #If there is no previous status or notifications, the default value is OK
  if [ -z "$old_status" ]; then new_status="NEW"; 
  else new_status=$old_status ; fi
  
  last_notification=`printf "$notifications" | grep "$server" | tail -1`
  #echo "$server Last notification  $last_notification"

  ok_notification=`echo "$last_notification" | grep "OKAY"`
  failure_notification=`echo "$last_notification" | grep "FAILURE"`
  
  message=$old_message
  timestamp=$old_timestamp
  type=$old_type
  
  if [ -n "$failure_notification" ]; then 
    new_status="FAILURE"; 
    message=`echo $failure_notification | grep -o "message = .*" | cut -c 11- | sed 's/"//g'`;
    timestamp=`echo $failure_notification | grep -o "\[.*\]" | sed 's/\[//' | sed 's/\]//'`;
    type=`echo $failure_notification | grep -o "type = [a-Z]*" | cut -d" " -f3`;
  fi
  if [ -n "$ok_notification" ]; then 
    new_status="OK"; 
    message=`echo $ok_notification | grep -o "message = .*" | cut -c 11- | sed 's/"//g'`;
    timestamp=`echo $ok_notification | grep -o "\[.*\]" | sed 's/\[//' | sed 's/\]//'`;
    type=`echo $ok_notification | grep -o "type = [a-Z]*" | cut -d" " -f3`;
  fi
  
  echo "$server;$new_status;$timestamp;$type;$message" >> $status_output
  
  echo "$separator{\"name\":\"$server\", \"status\":\"$new_status\",\"message\":\"$message\",\"timestamp\":\"$timestamp\",\"type\":\"$type\"}" >> $status_json

  separator=","  
done

echo "]}" >> $status_json

cat $status_json