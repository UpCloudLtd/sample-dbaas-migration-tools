#!/bin/bash
help()
{
    echo "Usage:
    disable-replication.sh [ Required options]
    Options:
      -u <UpCloud DBaaS UUID>
    Example:
      disable-replication.sh -u 09352622-5db9-4053-b3f2-791d3f8c8f63
    Use -h for infromation about this script
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
if [[ -z $UUID ]]
then
   echo "Missing required variable. You need to define all required arguments."
   echo
   help
fi
DATA="{ \"properties\": { \"migration\": null }}"
result=$(curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" -X PATCH -H Content-Type:application/json https://api.upcloud.com/1.3/database/$UUID -d "$DATA")
echo $result | jq
