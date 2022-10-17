# MySQL Examples
Database migration feature can be used to migrate your current MySQL databases to UpCloud DBaaS. Please test migration 
feature before using it in production enviroment. You should always have backup available in case something goes wrong with migration.

## Requirements

Your current MySQL/MariaDB server needs to have superuser that is allowed to log in from any IP address or from public 
IP address of your DBaaS active node.

After migration is done you need to change your DNS/host settings so that software connects to new DB cluster. 
With `mysqldump` method you should lock database from changes and DNS changes before you start the migration. 
With `replication` method you can allow replication to catch up, then change DNS settings and once everything is updated then disable replication.

### Requirements for replication method

- The source MySQL database should be in >= 5.7 and <= 8.0
  - MariaDB is not supported for replication method
- The target MSQL database should have at least version 8.0
- All databases have the same engine - InnoDB
- `gtid_mode` is ON on both the source and the target
- User on the source database has enough permissions to create a replication user and read data
- `server_id` on the source and the target do not overlap

You can change required parameters in runtime via MySQL cli. For example:
```
SET GLOBAL server_id=21;
SET GLOBAL enforce_gtid_consistency=ON;
SET GLOBAL gtid_mode=OFF_PERMISSIVE;
SET GLOBAL gtid_mode=ON_PERMISSIVE;
SET GLOBAL gtid_mode=ON;
```
### Requirements for mysqldump 

Method `mysqldump` does not have many specific requirements and can even be used with current MariaDB versions. Just like any other mysqldump migration you should lock 
source database from changes during migration and this can cause downtime. If you allow writing to database during `mysqldump` migration
you are likely going to have changes in database that are not migrated.

## Handling the migration
Logical replication is the default method which keeps the two databases synchronized until the replication is interrupted.
If the preconditions for logical replication are not met for a database, the migration falls back to using `pg_dump`.

You will need to manually create all existing users to UpCloud DBaaS cluster. You can do this via UpCloud HUB. After migration is finished 
you will need to change DNS settings or software settings to connect to UpCloud DBaaS cluster instead of old database server. 

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

First run script `create-dbaas-and-migrate.sh`
```
bash create-dbaas-and-migrate.sh -n updcloud-dbaas -S 2x2xCPU-4GB-50GB -z pl-waw1 -H yoursourceserver.com -U root -p YourPassW0rd -P 3306 -m dump -s false
{
 "backups": [],
  "components": [
    {
      "component": "mysql",
      "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11550,
      "route": "dynamic",
      "usage": "primary"
    },
...
  "name": "updcloud-dbaas",
  "node_count": 2,
  "node_states": [],
  "plan": "2x2xCPU-4GB-50GB",
  "powered": true,
  "properties": {
    "automatic_utility_network_ip_filter": true,
    "ip_filter": [],
    "migration": {
      "dbname": "mysql",
      "host": "185.70.198.14",
      "ignore_dbs": "",
      "method": "dump",
      "password": "YourPassW0rd",
      "port": 3306,
      "ssl": false,
      "username": "root"
    }
  },
  "uuid": "09bb9f50-6f52-4da6-b58f-905a0708d7e4",
  "state": "rebuilding",
  "title": "updcloud-dbaas",
  "type": "mysql",
  "update_time": "0001-01-01T00:00:00Z",
  "service_uri": "mysql://upadmin:AVNS_uYlk8kQ6Tna1lkOJT_F@updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com:11550/defaultdb?ssl-mode=REQUIRED",
  "service_uri_params": {
    "dbname": "defaultdb",
    "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
    "password": "AVNS_uYlk8kQ6Tna1lkOJT_F",
    "port": "11550",
    "ssl_mode": "REQUIRED",
    "user": "upadmin"
  },
 ...
  "zone": "pl-waw1"
}
UUID of created DBaaS service: 09bb9f50-6f52-4da6-b58f-905a0708d7e4
```
If you have want to create DBaaS via HUB use `start-migration.sh` instead.
```
bash start-migration.sh -u 09bb9f50-6f52-4da6-b58f-905a0708d7e4 -H 185.70.198.14 -U superuser -p YourPassW0rd -P 3306 -d defaultdb -m dump -s false
{
  "backups": [
    {
      "backup_time": "2022-10-17T07:55:54.691923Z",
      "data_size": 1872141684
    }
  ],
  ...
  "plan": "2x2xCPU-4GB-50GB",
  "powered": true,
  "properties": {
    "automatic_utility_network_ip_filter": true,
    "ip_filter": [],
    "long_query_time": 20,
    "migration": {
      "dbname": "defaultdb",
      "host": "185.70.198.14",
      "method": "dump",
      "password": "YourPassW0rd",
      "port": 3306,
      "ssl": false,
      "username": "superuser"
    }
  },
  "uuid": "09bb9f50-6f52-4da6-b58f-905a0708d7e4",
  "state": "running",
  "title": "updcloud-dbaas",
  "type": "mysql",
...
}

```

You can then monitor migration status with `monitor-dbaas.sh`

```
bash monitor-dbaas.sh -u 09bb9f50-6f52-4da6-b58f-905a0708d7e4
{
  "method": "",
  "seconds_behind_master": 0,
  "source_active": true,
  "status": "done",
  "databases": []
}
{
  "method": "mysqldump",
  "seconds_behind_master": 0,
  "source_active": true,
  "status": "running",
  "databases": [
    {
      "dbname": "test21",
      "method": "mysqldump",
      "status": "running"
    }
  ]
}
{
  "method": "mysqldump",
  "seconds_behind_master": 0,
  "source_active": true,
  "status": "done",
  "databases": [
    {
      "dbname": "test23",
      "method": "mysqldump",
      "status": "done"
    },
    {
      "dbname": "test21",
      "method": "mysqldump",
      "status": "done"
    },
    {
      "dbname": "test22",
      "method": "mysqldump",
      "status": "done"
    },
    {
      "dbname": "test24",
      "method": "mysqldump",
      "status": "done"
    }
  ]
}
```

Once migration is completed (`"status": "done"`) you can move SQL queries to new DBaaS service and if used you can disable replication with `disable-replication.sh`
```
bash disable-replication.sh -u 09fc3cec-fa71-4979-8aa3-ec7594cb944d
```

Please note that migration does not transfer users of source database server, you will need to create users to 
DBaaS via UpCloud Hub. Please check that all the data has been migrated before deleting data on the source servers. You 
can do the migration again if source data changes after first migration.

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
This script can be used to disable replication when you are using replication method for migration.

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


## Troubleshooting
If you are having issues with the migration you should check MySQL logs in source server and DBaaS logs in UpCloud Hub.
```
bash monitor-dbaas.sh -u 09bb9f50-6f52-4da6-b58f-905a0708d7e4  
{
  "error": "Migration process failed",
  "method": "",
  "seconds_behind_master": 0,
  "source_active": true,
  "status": "done",
  "databases": []
}
```
### DBaaS active node is unable to login to source database server
When DBaaS active node is unable to access database you might see following error in source database server logs.
```
Oct 17 08:51:21 mysql1-test mysqld[1024]: 10:36:54 112 [Warning] Access denied for user 'root'@'185-70-198-14.pl-waw1.upcloud.host' (using password: YES)
```

### DBaaS is missing some tables or data from source database
If you have changed or added data to source database after migration finished, it has not been copied to DBaaS service. 
You can re-do the migration in order to transfer missing data.

### Error during migration
If there is clear reason for migration failure you can see it in output of `monitor-dbaas.sh`.
```
{
  "error": "MySQL Errno - 13117: The replication receiver thread cannot start because the master has GTID_MODE = OFF and this server has GTID_MODE = ON.",
  "method": "replication",
  "seconds_behind_master": 0,
  "source_active": true,
  "status": "failed",
  "databases": [
    {
      "dbname": "test25",
      "method": "replication",
      "status": "failed"
    },
    {
      "dbname": "test23",
      "method": "replication",
      "status": "failed"
    },
    {
      "dbname": "test21",
      "method": "replication",
      "status": "failed"
    },
    {
      "dbname": "test22",
      "method": "replication",
      "status": "failed"
    },
    {
      "dbname": "test24",
      "method": "replication",
      "status": "failed"
    }
  ]
}
```