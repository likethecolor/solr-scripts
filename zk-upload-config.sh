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
# Script for uploading solr conf directory to zookeeper
#
# Arguments - all are required:
#
#   -d path: path to solr's conf directory
#                 [default:none]
#
#   -h host:port: host and port where zookeeper is running
#                 [default:$ZK_HOST_PORT]
#
#   -l path: path to solr's lib where the following jars are located
#              - commons-cli-*.jar
#              - commons-io-*.jar
#              - logj-*.jar
#              - slfj-api-*.jar
#              - slfj-logj-*.jar
#              - solr-core-*.jar
#              - solr-solrj-*.jar
#              - zookeeper-*.jar
#                 [default:$SOLR_ZK_LIB_DIR]
#
#   -n name: name of this configuration as it will appear in zookeeper:/configs
#                 [default:none]
#

dir=$(cd $(dirname $0); pwd)
source $dir/log

color_prefix='\033[40;31m'
color_suffix='\033[0m'

# create temporary file that will be used to log the actions of this script
#
log_file_base=`basename $0`
log_file=`mktemp -q /tmp/${log_file_base}.XXXXXX`
if test $? -ne 0; then
  echo -e "$0: ${color_prefix}Can't create temp file, exiting...$color_suffix"
  exit 1
fi

function usage() {
  echo "usage: $0 -d conf-dir -h host:port -l solr-lib -n conf-name"
  echo '  Uploads to zookeeper running on host:port the configuration directory located'
  echo '  at conf-dir giving the configuration the name conf-name.  The jars found in -l'
  echo '  are used to do the uploading.'
  if test "$@" != ''; then
    echo -e "---> ${color_prefix}$@$color_prefix"
  fi
}


# jars used to perform the upload
#
jars="commons-cli- \ 
commons-io- \
log4j- \
slf4j-api \
slf4j-log4j12- \
solr-core- \
solr-solrj- \
zookeeper-"

# defaults
#
conf_dir=''
conf_name=''
host_port=$ZK_HOST_PORT
solr_lib=$SOLR_ZK_LIB_DIR

while test -n "$1"; do
  case "$1" in
    '-d')
      shift
      conf_dir=$1
      shift
      ;;

    '-h')
      shift
      host_port=$1
      shift
      ;;

    '-l')
      shift
      solr_lib=$1
      shift
      ;;

    '-n')
      shift
      conf_name=$1
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
if test -z "$conf_dir"; then
  usage 'no conf-dir (-d)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$conf_name"; then
  usage 'no conf-name (-n)'
  echo -e "${color_prefix}exiting$color_suffix"
  exit 1
fi
if test -z "$host_port"; then
  if test -z "$ZK_HOST_PORT"; then
    usage 'no host:port (-h) and no $ZK_HOST_PORT'
    echo -e "${color_prefix}exiting$color_suffix"
  else
    host_port=$ZK_HOST_PORT
    log_stdout "using \$ZK_HOST_PORT env variable: $host_port"
  fi
fi
if test -z "$solr_lib"; then
  if test -z "$SOLR_ZK_LIB_DIR"; then
    usage 'no solr_lib (-l) and no $SOLR_ZK_LIB_DIR'
    echo -e "${color_prefix}exiting$color_suffix"
  else
    solr_lib=$SOLR_ZK_LIB_DIR
    log_stdout "using \$SOLR_ZK_LIB_DIR env variable: $solr_lib"
  fi
fi

exec > >(tee $log_file) 2>&1
log_stdout 'starting to upload conf'
log_stdout "using host:port: $host_port"
log_stdout " using conf-dir: $conf_dir"
log_stdout "using conf-name: $conf_name"
log_stdout "using  solr-lib: $solr_lib"

# create classpath
cp=''
for jar in $solr_lib/*;
do
  for patt in $jars
  do
    if [[ $jar =~ $patt ]]; then
      if test -n "$cp"; then
        cp="$cp:"
      fi
      cp="$cp$jar"
    fi
  done
done

# RUN!
#
cmd="java -cp $cp org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost ${host_port} -confdir ${conf_dir} -confname ${conf_name}"
log_stdout $cmd
$cmd
exit_code=$?

if test $exit_code -eq 0; then
  log_info 'success'
else
  log_error 'failed'
fi
log_stdout 'done'
exit $exit_code
