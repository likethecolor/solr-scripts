#!/bin/bash

# Copyright (c) 2015.  Dan Brown <dan@likethecolor.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#
# Original author: Dan Brown <dan@likethecolor.org>
#
# Script for creating a given collection.
#
# Arguments - all are required:
#
#   -c collection: name of collection
#                 [default:none]
#
#   -g config: name of the zookeeper configuraiton as found in zookeeper:/configs
#                 [default:none]
#
#   -h host:port: host and port where zookeeper is running
#                 [default:$SOLR_HOST_PORT]
#
#   -o file: path to file to which output will be written
#                 [default:mktemp -q /tmp/sc-create-collection...out]
#

dir=$(cd $(dirname $0); pwd)
source $dir/log

color_prefix='\033[40;31m'
color_suffix='\033[0m'

# create temporary file that will be used to log the actions of this script
#
log_file_base=`basename $0 '.sh'`
log_file=`mktemp -q /tmp/${log_file_base}.XXXXXX`
if test $? -ne 0; then
  echo -e "$0: ${color_prefix}Can't create temp file, exiting...$color_suffix"
  exit 1
fi
rm $log_file
log_file=$log_file.log
touch $log_file

function usage() {
  echo "usage: $0 -c collection-name -f zk-config-name -h host:port"
  echo '  Sends the CREATE action to the host creating a new collection having'
  echo '  collection-name and using the configuration called zk-config-name found in'
  echo '  zookeeper'
  echo
  echo '  note: the env variable $SOLR_HOST_PORT will be used as default value for -h'
  if test "$@" != ''; then
    echo -e "---> ${color_prefix}$@$color_suffix"
  fi
}

collection=''
config=''
host_port=$SOLR_HOST_PORT
output_file=''

while test -n "$1"; do
  case "$1" in
    '-c')
      shift
      collection=$1
      shift
      ;;

    '-f')
      shift
      config=$1
      shift
      ;;

    '-h')
      shift
      host_port=$1
      shift
      ;;

    '-o')
      shift
      output_file=$1
      shift
      ;;

    *)
      usage "cannot understand argument $1"
      echo -e "${color_prefix}exiting$color_suffix"
      exit 1
      ;;
  esac
done

if test -z "$collection"; then
  usage 'no collection-name (-c)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$config"; then
  usage 'no zk-config-name (-f)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$host_port"; then
  if test -z "$SOLR_HOST_PORT"; then
    usage 'no host:port (-h) and no $SOLR_HOST_PORT'
    echo -e "${color_prefix}exiting$color_suffix"
  else
    host_port=$SOLR_HOST_PORT
    log_stdout "using \$SOLR_HOST_PORT env variable: $host_port"
  fi
fi
if test -z "$output_file"; then
  log_info 'no output file (-o)'
  log_info 'using output file based on log file name'
  output_file='/tmp/'$(basename $log_file '.log').out
fi


exec > >(tee $log_file) 2>&1
log_stdout 'starting to create new collection using:'
log_stdout "        host:port: $host_port"
log_stdout "  collection name: $collection"
log_stdout "   zk-config-name: $config"
log_stdout "      output file: $output_file"
log_stdout "         log file: $log_file"

url="${host_port}/solr/admin/collections?action=CREATE&numShards=1&name=${collection}&collection.configName=${config}"

exit_code=1
client=$(which curl)
if test -n "$client"; then
  log_info "found curl: $client"
  log_stdout "curl '$url'"
  curl "$url" -s --output $output_file
  exit_code=$?
  log_info "curl call returned: $exit_code"
  if test $exit_code -eq 0; then
    if grep -q ERROR $output_file; then
      log_error "there are errors in the output file: $output_file"
      exit_code=1
    fi
  fi
else
  log_error 'cannot find curl in $PATH'
  exit_code=1
fi

if test $exit_code -eq 0; then
  log_info 'success'
else
  log_error 'failed'
fi
log_stdout 'done'
exit $exit_code
