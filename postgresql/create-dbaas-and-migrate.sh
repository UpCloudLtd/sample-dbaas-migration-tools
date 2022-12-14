#!/bin/bash
help()
{
    echo "Usage:
    create-dbaas-and-migrate.sh [ Required options]
    Required Options:
      -n <Upcloud DBaaS hostname>
      -S <UpCloud DBaaS plan size>
      -z <UpCloud zone/Datacenter>
      -H <Public Hostname or IPv4 address of server where to migrate data from>
      -U <Username for authentication with server where to migrate data from>
      -p <Password for authentication with the server where to migrate data from>
      -P <Port number of the server where to migrate data from>
      -s <Should we use SSL connection to source server during migration. Value true or false>
      -d <Name of database that exits in source database server used for bootstrapping the initial connection>
      -v <PostgreSQL version. For example 12, 13 or 14>
    Example:
      create-dbaas-and-migrate.sh -n updcloud-dbaas -S 2x2xCPU-4GB-50GB -z pl-waw1 -H yoursourceserver.com -U root -p YourPassW0rd -P 5432 -d postgres -s false -v 14
    Use -h for infromation about this script.
    "
    exit 2
}

if [[ $# -eq 0 ]]; then
   help
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -n)
      UPCLOUD_HOSTNAME=$2
      shift
      shift
      ;;
    -S)
      UPCLOUD_PLAN=$2
      shift
      shift
      ;;
    -z)
      UPCLOUD_ZONE=$2
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
    -s)
      SSL=$2
      shift
      shift
      ;;
    -v)
      PG_VERSION=$2
      shift
      shift
      ;;
    -h)
      help
      ;;

    -?)
      echo "Invalid option: -${OPTARG}."
      echo
      help
      ;;
  esac
done

if [[ -z $UPCLOUD_HOSTNAME || -z $UPCLOUD_PLAN || -z $UPCLOUD_ZONE || -z $PG_VERSION || -z $SOURCE_HOST || -z $SOURCE_USER || -z $SOURCE_PORT || -z $SOURCE_PASSWORD || -z $DBNAME || -z $SSL ]]
then
   echo "Missing required variable. You need to define all required arguments."
   echo
   help
fi

DATA="{ \"hostname_prefix\": \"$UPCLOUD_HOSTNAME\",  \"plan\": \"$UPCLOUD_PLAN\",  \"title\": \"$UPCLOUD_HOSTNAME\",  \"type\": \"pg\",  \"zone\": \"$UPCLOUD_ZONE\", \"properties\": { \"max_replication_slots\": 40, \"max_logical_replication_workers\": 10, \"version\": \"$PG_VERSION\",  \"migration\": { \"host\": \"$SOURCE_HOST\", \"dbname\": \"$DBNAME\", \"password\": \"$SOURCE_PASSWORD\", \"port\": $SOURCE_PORT, \"ssl\": $SSL, \"username\": \"$SOURCE_USER\" }}}}"
result=$(curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" -X POST -H Content-Type:application/json https://api.upcloud.com/1.3/database -d "$DATA")
echo $result | jq
UUID=$(echo $result| jq|grep uuid|cut -d'"' -f4)
echo "UUID of created DBaaS service:"
echo $UUID

