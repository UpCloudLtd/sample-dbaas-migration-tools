#!/bin/bash
help()
{
    echo "Usage:
    start-migration.sh [ Required options]
    Required options:
      -u <UpCloud DBaaS UUID>
      -H <Hostname or IPv4 address of server where to migrate data from>
      -U <Username for authentication with server where to migrate data from>
      -p <Password for authentication with the server where to migrate data from>
      -P <Port number of the server where to migrate data from>
      -m <Migration method. Value dump or replication>
      -s <Should we use SSL connection to source server during migration. Value true or false>
    Secondary options:
      -i <Comma separated list of databases to ignore>
      -d <Database name of bootstrapping the initial connection>
    Example:
      start-migration.sh -u 09352622-5db9-4053-b3f2-791d3f8c8f63 -H yoursourceserver.com -U root -p YourPassW0rd -P 3306 -d defaultdb -m replication -s false
    Use -h for infromation about this script.
    "
    exit 2
}

if [[ $# -eq 0 ]]; then
   help
fi
while [[ $# -gt 0 ]]; do
  case $1 in
    -u)
      UUID=$2
      shift
      shift
      ;;
    -H)
      SOURCE_HOST=$2
      shift
      shift
      ;;
    -U)
      SOURCE_USER=$2
      shift
      shift
      ;;
    -p)
      SOURCE_PASSWORD=$2
      shift
      shift
      ;;
    -P)
      SOURCE_PORT=$2
      shift
      shift
      ;;
    -d)
      DBNAME=$2
      shift
      shift
      ;;
    -m)
      METHOD=$2
      shift
      shift
      ;;
    -s)
      SSL=$2
      shift
      shift
      ;;
    -i)
      IGNORE_DBS=$2
      shift
      shift
      ;;
    -h)
      help
      ;;

    -*|--*)
      echo "Invalid option"
      echo
      help
      ;;
  esac
done

if [[ -z $UUID || -z $SOURCE_HOST || -z $SOURCE_USER || -z $SOURCE_PORT || -z $SOURCE_PASSWORD || -z $METHOD || -z $SSL ]]
then
   echo "Missing required variable. You need to define all required arguments."
   echo
   help
fi
DATA="{ \"properties\": { \"migration\": { \"host\": \"$SOURCE_HOST\", \"dbname\": \"$DBNAME\", \"ignore_dbs\": \"$IGNORE_DBS\", \"method\": \"$METHOD\", \"password\": \"$SOURCE_PASSWORD\", \"port\": $SOURCE_PORT, \"ssl\": $SSL, \"username\": \"$SOURCE_USER\" }}}"
result=$(curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" -X PATCH -H Content-Type:application/json https://api.upcloud.com/1.3/database/$UUID -d "$DATA")
echo $result | jq
