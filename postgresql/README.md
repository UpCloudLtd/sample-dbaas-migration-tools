# PostgreSQL examples
Database migration feature can be used to migrate your current PostgreSQL databases to UpCloud DBaaS. It supports both logical replication and also using a dump and restore process.

Logical replication is the default method and once successfully set up, this keeps the two databases synchronized until 
the replication is interrupted. If the preconditions for logical replication are not met for a database, the migration falls back to using pg_dump.

Regardless of the migration method used, the migration tool first performs a schema dump and migration to ensure schema compatibility.
## Requirements

Your PostgreSQL server needs to publicly available or it needs to be attached to Upcloud Utility network or UpCloud SDN network.
You also need to have superuser with access to login to source database server from UpCloud DBaaS active node.

After migration is done you need to change your DNS/host settings so that software connects to new UpCloud DBaaS cluster. 
PostgreSQL migration is done with replication, but if replication fails system will fall back to data dump automatically. This user needs
to be configured to pg_hba.conf.

### Requirements for logical replication

- Requires PostgreSQL 10 or newer
 - Please use same PostgreSQL major version for source and destination when possible
- `wal_level` needs to be `logical`
- Supports only FOR ALL TABLES publication in source
- Migration requires replication slots so if you are already using all of them you need to increase replication slots
- You need superuser or superuser-like privileges in both source and target database. 
  - Or you can use [aiven-extras](https://github.com/aiven/aiven-extras) extension 

## Handling the migration
Logical replication is the default method which keeps the two databases synchronized until the replication is interrupted.
If the preconditions for logical replication are not met for a database, the migration falls back to using pg_dump.

You will need to manually create all existing users to UpCloud DBaaS cluster. You can do this via HUB.
## Troubleshooting
### DBaaS active node is unable to login to source database
After you have enabled migration you might see postgresql log something similar this:
```
2022-10-10 10:38:21.184 UTC [8823] superuser@test FATAL:  no pg_hba.conf entry for host "5.22.221.26", user "superuser", database "test3", SSL on
2022-10-10 10:38:21.188 UTC [8824] superuser@test FATAL:  no pg_hba.conf entry for host "5.22.221.26", user "superuser", database "test3", SSL off
2022-10-10 10:39:10.802 UTC [8838] superuser@test FATAL:  no pg_hba.conf entry for host "5.22.221.26", user "superuser", database "test3", SSL on
2022-10-10 10:39:10.804 UTC [8839] superuser@test FATAL:  no pg_hba.conf entry for host "5.22.221.26", user "superuser", database "test3", SSL off
```
This means that DBaaS active node is trying to login to your database server.

### Migration fails 
If migration initially fails you should disable the migration and fix issues preventing from migration to continue.

### DBaaS migration starts, but you need to try again
If you are able to enable DBaaS migration, but then something goes wrong, and you need to start from the beginning. 

#### PostgreSQL publication exits in table
If you get following error logs in source database server 
```
2022-10-10 10:46:26.684 UTC [8995] superuser@test ERROR:  publication "aiven_db_migrate_ad0234829205b9033196ba818f7a872b_pub" already exists
2022-10-10 10:46:26.684 UTC [8995] superuser@test STATEMENT:  CREATE PUBLICATION aiven_db_migrate_ad0234829205b9033196ba818f7a872b_pub FOR ALL TABLES WITH (publish = 'INSERT,UPDATE,DELETE,TRUNCATE')
```
This means migration started but something when wrong with it. You can try again by disabling migration or if that is 
no longer possible due to deleting DBaaS service then you need to check if any migration publication exists.
```
test=# select * from pg_catalog.pg_publication; 
  oid  |                        pubname                        | pubowner | puballtables | pubinsert | pubupdate | pubdelete | pubtruncate | pubviaroot 
-------+-------------------------------------------------------+----------+--------------+-----------+-----------+-----------+-------------+------------
 17274 | aiven_db_migrate_098f6bcd4621d373cade4e832627b4f6_pub |    16387 | t            | t         | t         | t         | t           | f
(1 row)
```
and drop these with
```
DROP PUBLICATION IF EXISTS aiven_db_migrate_098f6bcd4621d373cade4e832627b4f6_pub;
```
And now you can start to enable migration again.

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