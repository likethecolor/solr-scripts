# Solr Scripts

## About

I do quite a bit of work with SOLR (Cloud).  There are a few actions that happen over and over.  I created these scripts to handle the repetitiveness.

### Be sure to see the [Changelog](https://github.com/likethecolor/solr-scripts/blob/master/CHANGELOG.md)

## Scripts

### sc-create-alias.sh

Script for creating an alias.

- -a alias-name: name of alias [default:none]

- -c collection: name of collection [default:none]

- -h host:port: host and port where zookeeper is running [default:localhost:8983]

- -o file: path to file to which output will be written [default:mktemp -q /tmp/sc-create-alias...out]

### sc-delete-alias.sh

Script for deleting an alias.

- -a alias-name: name of alias [default:none]

- -h host:port: host and port where zookeeper is running [default:localhost:8983]

### sc-create-collection.sh

Script for creating a given collection.

- -c collection: name of collection [default:none]

- -g config: name of the zookeeper configuraiton as found in zookeeper:/configs [default:none]

- -h host:port: host and port where zookeeper is running [default:localhost:8983]

- -o file: path to file to which output will be written [default:mktemp -q /tmp/sc-create-collection...out]

### sc-delete-collection.sh

Script for deleting a given collection.

- -c collection: name of collection [default:none]

- -d: give to delete the index files [default:false]

- -h host:port: host and port where zookeeper is running [default:none]

- -o file: path to file to which output will be written [default:mktemp -q /tmp/sc-delete-collection...out]

### sc-delete-data.sh

Script for deleting all data of a given collection.

- -c collection: name of collection [default:none]

- -h host:port: host and port where zookeeper is running [default:localhost:8983]

- -o file: path to file to which output will be written [default:mktemp -q /tmp/sc-delete-data....]

### sc-update-data.sh

Script for updating a value in a document.

- -c collection: name of collection [default:none]

- -h host:port: host and port where zookeeper is running [default:localhost:8983]

- -f field-name: name of the field whose value is to be modified [default:none]

- -i unique id field: name of the unique id field of the document to change [default:none]

- -n new value: value to change to [default:none]

- -o file: path to file to which output will be written [default:mktemp -q /tmp/sc-update-data....out]

- -u unique id value: value of the unique id of the document to change [default:none]

### zk-upload-config.sh

Script for uploading solr conf directory to zookeeper

- -d path: path to solr's conf directory [default:none]

- -h host:port: host and port where zookeeper is running [default:localhost:2181]

- -l path: path to solr's lib where the following jars are located [default:none]

  |    jars                 |
  |:-----------------------:|
  | commons-cli-1.2.jar     |
  | commons-io-2.1.jar      |
  | log4j-1.2.16.jar        |
  | slf4j-api-1.6.6.jar     |
  | slf4j-log4j12-1.6.6.jar |
  | solr-core-4.6.0.jar     |
  | solr-solrj-4.6.0.jar    |
  | zookeeper-3.4.5.jar     |

- -n name: name of this configuration as it will appear in zookeeper:/configs [default:none]
