# MySQL Examples
Database migration feature can be used to migrate your current MySQL or MariaDB databases to UpCloud DBaaS.

## Requirements

Your current MySQL/MariaDB server needs to have superuser that is allowed to log in from any IP address or from public IP address of your DBaaS active node.

After migration is done you need to change your DNS/host settings so that software connects to new DB cluster. 
With `mysqldump` method you should lock database from changes and DNS changes before you start the migration. 
With `replication` method you can allow replication to catch up, then change DNS settings and once everything is updated then disable replication.

### Requirements for replication method

- The source database should be in >= 5.7 and <= 8.0
- The target database should have at least version 8.0
- All databases have the same engine - InnoDB
- `gtid_mode` is ON on both the source and the target
- User on the source database has enough permissions to create a replication user and read data
- `server_id` on the source and the target do not overlap

You can change required parameters in runtime via MySQL cli.
```
SET GLOBAL server_id=21
SET GLOBAL enforce_gtid_consistency=ON;
SET GLOBAL gtid_mode=OFF_PERMISSIVE
SET GLOBAL gtid_mode=ON_PERMISSIVE
SET GLOBAL gtid_mode=ON
```
### Requirements for mysqldump 

Method `mysqldump` does not have many specific requirements and can even be used with current MariaDB versions. Just like any other mysqldump migration you should lock 
source database from changes during migration and this can cause downtime. If you allow writing to database during `mysqldump` migration
you are likely going to have changes in database that are not migrated.

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
Example 
```
bash$ ./create-dbaas-and-migrate.sh -n updcloud-dbaas -S 2x2xCPU-4GB-50GB -z pl-waw1 -H yoursourceserver.com -U root -p YourPassW0rd -P 3306 -m dump -s false
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
    {
      "component": "mysql",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11550,
      "route": "dynamic",
      "usage": "replica"
    },
    {
      "component": "mysqlx",
      "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "primary"
    },
    {
      "component": "mysqlx",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "replica"
    }
  ],
  "create_time": "0001-01-01T00:00:00Z",
  "maintenance": {
    "dow": "saturday",
    "time": "19:07:20",
    "pending_updates": []
  },
  "name": "updcloud-dbaas",
  "node_count": 2,
  "node_states": [],
  "plan": "2x2xCPU-4GB-50GB",
  "powered": true,
  "properties": {
    "automatic_utility_network_ip_filter": true,
    "ip_filter": [],
    "migration": {
      "dbname": "",
      "host": "yoursourceserver.com",
      "ignore_dbs": "",
      "method": "dump",
      "password": "YourPassW0rd",
      "port": 3306,
      "ssl": false,
      "username": "root"
    }
  },
  "uuid": "09b309c8-f977-404c-9d7d-10be534f8cff",
  "state": "rebuilding",
  "title": "updcloud-dbaas",
  "type": "mysql",
  "update_time": "0001-01-01T00:00:00Z",
  "service_uri": "mysql://upadmin:AVNS_Z3TFacuYqgDeH0cowy8@updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com:11550/defaultdb?ssl-mode=REQUIRED",
  "service_uri_params": {
    "dbname": "defaultdb",
    "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
    "password": "AVNS_Z3TFacuYqgDeH0cowy8",
    "port": "11550",
    "ssl_mode": "REQUIRED",
    "user": "upadmin"
  },
  "users": [
    {
      "username": "upadmin",
      "authentication": "caching_sha2_password",
      "type": "primary"
    }
  ],
  "databases": [
    {
      "name": "defaultdb"
    }
  ],
  "zone": "pl-waw1"
}
UUID of created DBaaS service: 09b309c8-f977-404c-9d7d-10be534f8cff
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
Example 
```
bash$ ./start-migration.sh -u 09b309c8-f977-404c-9d7d-10be534f8cff  -H yoursourceserver.com -U root -p YourPassW0rd -P 3306 -d defaultdb -m dump -s false
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
    {
      "component": "mysql",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11550,
      "route": "dynamic",
      "usage": "replica"
    },
    {
      "component": "mysqlx",
      "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "primary"
    },
    {
      "component": "mysqlx",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "replica"
    }
  ],
  "create_time": "2022-10-03T08:37:11Z",
  "maintenance": {
    "dow": "saturday",
    "time": "19:07:20",
    "pending_updates": []
  },
  "name": "updcloud-dbaas",
  "node_count": 2,
  "node_states": [
    {
      "name": "updcloud-dbaas-1",
      "role": "standby",
      "state": "setting_up_vm"
    }
  ],
  "plan": "2x2xCPU-4GB-50GB",
  "powered": true,
  "properties": {
    "automatic_utility_network_ip_filter": true,
    "ip_filter": [],
    "migration": {
      "dbname": "defaultdb",
      "host": "yoursourceserver.com",
      "method": "dump",
      "password": "YourPassW0rd",
      "port": 3306,
      "ssl": false,
      "username": "root"
    }
  },
  "uuid": "09b309c8-f977-404c-9d7d-10be534f8cff",
  "state": "rebuilding",
  "title": "updcloud-dbaas",
  "type": "mysql",
  "update_time": "2022-10-03T08:37:11Z",
  "service_uri": "mysql://upadmin:AVNS_Z3TFacuYqgDeH0cowy8@updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com:11550/defaultdb?ssl-mode=REQUIRED",
  "service_uri_params": {
    "dbname": "defaultdb",
    "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
    "password": "AVNS_Z3TFacuYqgDeH0cowy8",
    "port": "11550",
    "ssl_mode": "REQUIRED",
    "user": "upadmin"
  },
  "users": [
    {
      "username": "upadmin",
      "authentication": "caching_sha2_password",
      "type": "primary"
    }
  ],
  "databases": [
    {
      "name": "defaultdb"
    }
  ],
  "zone": "pl-waw1"
}
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
Example
```
bash$ ./disable-replication.sh -u 09b309c8-f977-404c-9d7d-10be534f8cff
{
  "backups": [
    {
      "backup_time": "2022-10-03T08:39:14.422852Z",
      "data_size": 1872141870
    }
  ],
  "components": [
    {
      "component": "mysql",
      "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11550,
      "route": "dynamic",
      "usage": "primary"
    },
    {
      "component": "mysql",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11550,
      "route": "dynamic",
      "usage": "replica"
    },
    {
      "component": "mysqlx",
      "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "primary"
    },
    {
      "component": "mysqlx",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "replica"
    }
  ],
  "create_time": "2022-10-03T08:37:11Z",
  "maintenance": {
    "dow": "saturday",
    "time": "19:07:20",
    "pending_updates": []
  },
  "name": "updcloud-dbaas",
  "node_count": 2,
  "node_states": [
    {
      "name": "updcloud-dbaas-1",
      "role": "master",
      "state": "running"
    },
    {
      "name": "updcloud-dbaas-2",
      "role": "standby",
      "state": "syncing_data"
    }
  ],
  "plan": "2x2xCPU-4GB-50GB",
  "powered": true,
  "properties": {
    "automatic_utility_network_ip_filter": true,
    "ip_filter": [],
    "migration": null
  },
  "uuid": "09b309c8-f977-404c-9d7d-10be534f8cff",
  "state": "rebalancing",
  "title": "updcloud-dbaas",
  "type": "mysql",
  "update_time": "2022-10-03T08:38:27Z",
  "service_uri": "mysql://upadmin:AVNS_Z3TFacuYqgDeH0cowy8@updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com:11550/defaultdb?ssl-mode=REQUIRED",
  "service_uri_params": {
    "dbname": "defaultdb",
    "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
    "password": "AVNS_Z3TFacuYqgDeH0cowy8",
    "port": "11550",
    "ssl_mode": "REQUIRED",
    "user": "upadmin"
  },
  "users": [
    {
      "username": "upadmin",
      "authentication": "caching_sha2_password",
      "type": "primary"
    }
  ],
  "databases": [
    {
      "name": "defaultdb"
    }
  ],
  "zone": "pl-waw1"
}

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
Example
```
bash$ ./monitor-dbaas.sh -u 09b309c8-f977-404c-9d7d-10be534f8cff
{
  "backups": [
    {
      "backup_time": "2022-10-03T08:39:14.422852Z",
      "data_size": 1872141870
    }
  ],
  "components": [
    {
      "component": "mysql",
      "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11550,
      "route": "dynamic",
      "usage": "primary"
    },
    {
      "component": "mysql",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11550,
      "route": "dynamic",
      "usage": "replica"
    },
    {
      "component": "mysqlx",
      "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "primary"
    },
    {
      "component": "mysqlx",
      "host": "replica-updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
      "port": 11554,
      "route": "dynamic",
      "usage": "replica"
    }
  ],
  "create_time": "2022-10-03T08:37:11Z",
  "maintenance": {
    "dow": "saturday",
    "time": "19:07:20",
    "pending_updates": []
  },
  "name": "updcloud-dbaas",
  "node_count": 2,
  "node_states": [
    {
      "name": "updcloud-dbaas-1",
      "role": "master",
      "state": "running"
    },
    {
      "name": "updcloud-dbaas-2",
      "role": "standby",
      "state": "syncing_data"
    }
  ],
  "plan": "2x2xCPU-4GB-50GB",
  "powered": true,
  "properties": {
    "automatic_utility_network_ip_filter": true,
    "ip_filter": [],
    "migration": null
  },
  "uuid": "09b309c8-f977-404c-9d7d-10be534f8cff",
  "state": "rebalancing",
  "title": "updcloud-dbaas",
  "type": "mysql",
  "update_time": "2022-10-03T08:41:56Z",
  "service_uri": "mysql://upadmin:AVNS_Z3TFacuYqgDeH0cowy8@updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com:11550/defaultdb?ssl-mode=REQUIRED",
  "service_uri_params": {
    "dbname": "defaultdb",
    "host": "updcloud-dbaas-mystmtdaytdt.db.upclouddatabases.com",
    "password": "AVNS_Z3TFacuYqgDeH0cowy8",
    "port": "11550",
    "ssl_mode": "REQUIRED",
    "user": "upadmin"
  },
  "users": [
    {
      "username": "upadmin",
      "authentication": "caching_sha2_password",
      "type": "primary"
    }
  ],
  "databases": [
    {
      "name": "defaultdb"
    }
  ],
  "zone": "pl-waw1"
}
```