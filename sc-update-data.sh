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
# Script for updating a value in a document.
#
# Arguments - all are required:
#
#   -c collection: name of collection
#                 [default:none]
#
#   -h host:port: host and port where zookeeper is running
#                 [default:$SOLR_HOST_PORT]
#
#   -f field-name: name of the field whose value is to be modified
#                 [default:none]
#
#   -i unique id field: name of the unique id field of the document to change
#                 [default:none]
#
#   -n new value: value to change to
#                 [default:none]
#
#   -o file: path to file to which output will be written
#                 [default:mktemp -q /tmp/sc-update-data....out]
#
#   -u unique id value: value of the unique id of the document to change
#                 [default:none]
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
  echo "usage: $0 -c collection-name -h host:port -f field-name -i id-field -n new-value -o output-file -u unique-id"
  echo "  Change the value of a solr document.  Given the unique id (-u) and that id's"
  echo '  field name (-i) change the value of the field (-f) to the new value (-n).  The'
  echo '  output of the call will be stored in the output file (-o).'
  echo
  echo '  note: the env variable $SOLR_HOST_PORT will be used as default value for -h'
  if test "$@" != ''; then
    echo -e "---> ${color_prefix}$@${color_suffix}"
  fi
}

collection=my-collection
host_port=$SOLR_HOST_PORT
field_name=''
new_value=''
unique_id_field_name=''
unique_id_field_value=''

while test -n "$1"; do
  case "$1" in
    '-c')
      shift
      collection=$1
      shift
      ;;

    '-h')
      shift
      host_port=$1
      shift
      ;;

    '-f')
      shift
      field_name=$1
      shift
      ;;

    '-i')
      shift
      unique_id_field_name=$1
      shift
      ;;

    '-n')
      shift
      new_value=$1
      shift
      ;;

    '-o')
      shift
      output_file=$1
      shift
      ;;

    '-u')
      shift
      unique_id_value=$1
      shift
      ;;

    *)
      usage "cannot understand argument $1"
      echo -e "${color_prefix}exiting$color_suffix"
      exit 1
      ;;
  esac
done

# verify that all args are not empty
#
if test -z "$collection"; then
  usage 'no collection (-c)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$field_name"; then
  usage 'no field name (-f)'
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
if test -z "$new_value"; then
  usage 'no new value (-n)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$unique_id_field_name"; then
  usage 'no unique id field name (-i)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$unique_id_value"; then
  usage 'no unique field value (-u)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi

exec > >(tee $log_file) 2>&1
log_stdout_sep
log_stdout 'starting to change value using:'
log_stdout "             collection: $collection"
log_stdout "              host:port: $host_port"
log_stdout "             field name: $field_name"
log_stdout "              new value: $new_value"
log_stdout "               log file: $log_file"
log_stdout "            output file: $output_file"
log_stdout "   unique id field name: $unique_id_field_name"
log_stdout "  unique id field value: $unique_id_field_value"
log_stdout_sep

exit_code=1
client=$(which curl)
if test -n "$client"; then
  log_info "found curl: $client"
  log_info curl http://$host_port/solr/$collection/update?commit=true -s --output $output_file -H 'Content-Type: text/xml' --data-binary "<add><doc><field name=\"$unique_id_field_name\">$unique_id_value</field><field name=\"$field_name\" update=\"set\">$new_value</field></doc></add>"
  curl http://$host_port/solr/$collection/update?commit=true -s --output $output_file -H 'Content-Type: text/xml' --data-binary "<add><doc><field name=\"$unique_id_field_name\">$unique_id_value</field><field name=\"$field_name\" update=\"set\">$new_value</field></doc></add>" 2>&1
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
