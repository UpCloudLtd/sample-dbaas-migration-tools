#!/bin/bash
help()
{
    echo "Usage:
    start-migration-pre-check.sh [ Required options]
    Required options:
      -u <UpCloud DBaaS UUID>
      -H <Hostname or IP address of server where to migrate data from>
      -U <Username for authentication with server where to migrate data from>
      -p <Password for authentication with the server where to migrate data from>
      -P <Port number of the server where to migrate data from>
      -m <Migration method. Value dump or replication>
      -s <Should we use SSL connection to source server during migration. Value true or false>
    Secondary options:
      -i <Comma separated list of databases to ignore>
      -d <Database name of bootstrapping the initial connection>
    Example:
      start-migration-pre-check.sh -u 09352622-5db9-4053-b3f2-791d3f8c8f63 -H yoursourceserver.com -U root -p YourPassW0rd -P 3306 -d defaultdb -m replication -s true
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

echo -e "Creating migration check task… \n"

DATA="{\"migration_check\": { \"source_service_uri\": \"postgres://$SOURCE_USER:$SOURCE_PASSWORD@$SOURCE_HOST:$SOURCE_PORT/$DBNAME\" }, \"operation\": \"migration_check\"}"
result=$(curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" -X POST -H Content-Type:application/json https://api.upcloud.com/1.3/database/$UUID/task -d "$DATA") 
taskId=$( jq -r '.id?' <<< $result)

if [[ "$taskId" == "null" ]]; then
  echo -e "Error: failed to create migration_check task!" 
  echo "$result" 
  exit 1
fi

echo -e "Success: migration check task created"
echo -e "id: $taskId \n"


echo -e "Polling for migration check task result... \n"
taskFinished=0
count=1
while [ $taskFinished -eq 0 ]; do
    sleep 3
    taskResult=$(curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" -X GET -H Content-Type:application/json https://api.upcloud.com/1.3/database/$UUID/task/$taskId)
    echo "Task Result : poll #$count "
    echo "$taskResult" | jq
    successResult=$( jq -r '.success?' <<< $taskResult)
    if [ $successResult == "true" ] || [ $successResult == "false" ]; then
      taskFinished=1
      echo -e "\n"
      echo "migration check task completed"
      break
    fi
    ((count=count+1))
    echo -e "\n"
done
