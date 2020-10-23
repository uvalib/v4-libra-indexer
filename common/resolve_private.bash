#!/usr/bin/env bash
#
# helper to sync a local directory to an s3 bucket
#

#set -x

# source helpers
SCRIPTDIR=$( (cd -P $(dirname $0) && pwd) )

# print a message and exit
function report_and_exit {

   local MESSAGE=$1
   echo $MESSAGE
   exit 1
}

# print an error message and exit
function error_and_exit {

   local MESSAGE="ERROR: $1"
   report_and_exit "$MESSAGE"
}

# ensure the specific tool is available
function ensure_tool_available {

   local TOOL_NAME=$1
   which $TOOL_NAME > /dev/null 2>&1
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$TOOL_NAME is not available in this environment"
   fi
}

function help_and_exit {
   report_and_exit "use: $(basename $0) <hostname>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   help_and_exit
fi

# input parameters for clarity
HOSTNAME=$1
shift

# check our environment requirements
#if [ -z "$AWS_ACCESS_KEY_ID" ]; then
#   error_and_exit "AWS_ACCESS_KEY_ID is not defined in the environment"
#fi
#if [ -z "$AWS_SECRET_KEY" ]; then
#   error_and_exit "AWS_SECRET_KEY is not defined in the environment"
#fi
#if [ -z "$AWS_DEFAULT_REGION" ]; then
#   error_and_exit "AWS_DEFAULT_REGION is not defined in the environment"
#fi

# ensure we have the jq tool available
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# ensure we have the aws command line tool available
AWS_CMD_TOOL=aws
ensure_tool_available $AWS_CMD_TOOL

# split the name into the host and the zone
HOST=$(echo $HOSTNAME | awk -F. '{print $1}')
ZONE=${HOSTNAME#${HOST}.}

ZONE_ID=$($AWS_CMD_TOOL route53 list-hosted-zones 2> /dev/null | $JQ_TOOL -r ".HostedZones[] | select(.Name == \"${ZONE}.\").Id")
if [ -z "$ZONE_ID" ]; then
   error_and_exit "Cannot determine zone identifier for $ZONE"
fi

IP=$($AWS_CMD_TOOL route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" 2> /dev/null  | $JQ_TOOL -r ".ResourceRecordSets[] | select(.Name == \"${HOSTNAME}.\").ResourceRecords[0].Value")
if [ -z "$IP" ]; then
   error_and_exit "Cannot determine ip address for $HOSTNAME"
fi

echo "$IP"

# all over
exit 0

#
# end of file
#

