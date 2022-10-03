# PostgreSQL examples
Database migration feature can be used to migrate your current PostgreSQL databases to UpCloud DBaaS.

## Requirements

Your PostgreSQL server needs to have superuser that is allowed to log in from any IP address or from public IP address of your DBaaS active node.

After migration is done you need to change your DNS/host settings so that software connects to new UpCloud DBaaS cluster. 
PostgreSQL migration is done with replication, but if replication fails system will fall back to data dump automatically. 

### Requirements for replication method

- Requires PostgreSQL 10 or newer
- `wal_level` needs to be `logical`
- Supports only FOR ALL TABLES publication in source
- You need superuser or superuser-like privileges in both source and target database. 
  - Or you can use [aiven-extras](https://github.com/aiven/aiven-extras) extension 

## Hub usage

## Bash script usage 

We have provided you with following bash scripts `start-migration.sh`, `disable-replication.sh` and `create-dbaas-and-migrate.sh` that can be used to 
migrate your database to UpCloud DBaaS. You can monitor migration status and UpCloud DBaaS status with `monitor-dbaas.sh`. 

You can migrate your database to UpCloud DBaaS with `create-dbaas-and-migrate.sh` if you need to create the UpCloud DBaaS service at the same time. If you 
have existing UpCloud DBaaS or you want to create it via [UpCloud Control Panel](https://hub.upcloud.com/) you can use `start-migration.sh` script. 

### Bash script example
First you need to define your UpCloud HUB/API username and password as environment variable to allow included scripts to work.
```
export UPCLOUD_USERNAME=Your_username
export UPCLOUD_PASSWORD=Your_password
```

#### create-dbaas-and-migrate.sh
This script creates DBaaS and starts migration from source database server to new DBaaS system. 

```
Usage:
    create-dbaas-and-migrate.sh [ Options]
    Required options:
      -n <Upcloud DBaaS hostname>
      -S <UpCloud DBaaS plan size>
      -z <UpCloud zone/Datacenter>
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
      create-dbaas-and-migrate.sh -n updcloud-dbaas -S 2x2xCPU-4GB-50GB -z pl-waw1 -H yoursourceserver.com -U root -p YourPassW0rd -P 3306 -m dump -s false
    Use -h for infromation about this script.
```

#### start-migration.sh
This script can be used to start migration to UpCloud DBaaS service that is already running.
```
Usage:
    start-migration.sh [ Required options]
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
      start-migration.sh -u 09352622-5db9-4053-b3f2-791d3f8c8f63 -H yoursourceserver.com -U root -p YourPassW0rd -P 3306 -d defaultdb -m replication -s false
    Use -h for infromation about this script.
```

#### disable-replication.sh
This script can be used to diable replication when you are using replication method for migration.

```
Usage:
    disable-replication.sh [ Required options]
    Options:
      -u <UpCloud DBaaS UUID>
    Example:
      disable-replication.sh -u 09352622-5db9-4053-b3f2-791d3f8c8f63
    Use -h for infromation about this script
```

#### monitor-dbaas.sh
This script can be used to monitor UpCloud DBaaS service and migration status.
```
Usage:
    monitor-dbaas.sh [ Required options]
    Options:
      -u <UpCloud DBaaS UUID>
    Example:
      monitor-dbaas.sh -u 09352622-5db9-4053-b3f2-791d3f8c8f63
    Use -h for infromation about this script

```