# Changelog

## 1.0.2 - Nov 23, 2015
- variable name used was $host, should be $host_port
- added sc-delete-replica.sh

## 1.0.1 - Nov 23, 2015
- the script was lookng for specific versions on the jar files in solr lib
- removed that requirement so that any version of the specific jar names will be used

## 1.0.0 - Nov 19, 2015
- Initial check in of:
    - sc-create-alias.sh
    - sc-create-collection.sh
    - sc-delete-alias.sh
    - sc-delete-collection.sh
    - sc-delete-data.sh
    - sc-update-data.sh
    - zk-upload-config.sh
