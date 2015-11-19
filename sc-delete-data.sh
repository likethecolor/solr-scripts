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
# Script for deleting all data of a given collection.
#
# Arguments - all are required:
#
#   -c collection: name of collection
#                 [default:none]
#
#   -h host:port: host and port where zookeeper is running
#                 [default:localhost:8983]
#
#   -o file: path to file to which output will be written
#                 [default:mktemp -q /tmp/sc-delete-data....]
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

host_port='localhost:8983'
collection=''
dry_run=0

function usage() {
  echo "usage: $0 -h host:port -c collection-name -o output-file [--dry-run]"
  echo '  Sends the DELETE action to the host deleting all data in the specified'
  echo '  collection-name.  If --dry-run is provided only the url will be printed,'
  echo '  nothing will be deleted.'
  if test "$@" != ''; then
    echo -e "---> $color_prefix$@$color_suffix"
  fi
}

while test -n "$1"; do
  case "$1" in
    '-h')
      shift
      host_port=$1
      shift
      ;;

    '-c')
      shift
      collection=$1
      shift
      ;;

    '-o')
      shift
      output_file=$1
      shift
      ;;

    '--dry-run')
      shift
      dry_run=1
      ;;

    *)
      usage "cannot understand argument $1"
      echo -e "${color_prefix}exiting$color_suffix"
      exit 1
      ;;
  esac
done

if test -z "$host_port"; then
  usage 'no host:port (-h)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$collection"; then
  usage 'no collection name (-c)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$output_file"; then
  log_info 'no output file (-o)'
  log_info 'using output file based on log file name'
  output_file='/tmp/'$(basename $log_file '.log').out
fi

exec > >(tee $log_file) 2>&1
log_stdout_sep
log_info 'starting delete using:'
log_info "    host:port: $host_port"
log_info "   collection: $collection"
log_info "     log file: $log_file"
log_info "  output file: $output_file"
log_stdout_sep

delete_url="http://${host_port}/solr/${collection}/update/?stream.body=<delete><query>*:*</query></delete>&commit=true&optimize=true"

exit_code=1
client=$(which curl)
if test -n "$client"; then
  log_info "found curl: $client"
  if test $dry_run -eq 0; then
    curl $delete_url -s --output $output_file 2>&1
    exit_code=$?
    if test $exit_code -eq 0; then
      if grep -q ERROR $output_file; then
        log_error "there are errors in the output file: $output_file"
        exit_code=1
      fi
    fi
  else
    log_info 'DRY RUN'
    log_info $delete_url
    exit_code=0
  fi
else
  log_error 'cannot find curl in $PATH'
fi

if test $exit_code -eq 0; then
  log_info 'success'
else
  log_error 'failed'
fi
log_info 'done'
exit $exit_code
