#!/usr/bin/env bash

#repos
#postgres
yum -y install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
#epel
yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#Foreman
yum -y install https://yum.theforeman.org/releases/1.16/el7/x86_64/foreman-release.rpm
#puppet
yum -y install https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
#sclo repos
yum -y install centos-release-scl centos-release-scl-rh

#set selinux to permissive
setenforce 0

#updating hosts files
echo "192.168.50.2 ipa.local ipa" >> /etc/hosts
echo "192.168.50.3 foreman.local foreman" >> /etc/hosts
echo "192.168.50.4 test.local test" >> /etc/hosts

#installing postgresql96
yum -y install postgresql96
yum -y install postgresql96-server
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl enable postgresql-9.6
systemctl start postgresql-9.6

#adding the postgres hba rules
echo local all postgres trust > /var/lib/pgsql/9.6/data/pg_hba.conf
echo local all all ident >> /var/lib/pgsql/9.6/data/pg_hba.conf
echo host all postgres 127.0.0.1/32 md5 >> /var/lib/pgsql/9.6/data/pg_hba.conf
echo host all postgres 0.0.0.0/0 reject >> /var/lib/pgsql/9.6/data/pg_hba.conf
echo host all all 127.0.0.1/32 trust >> /var/lib/pgsql/9.6/data/pg_hba.conf
echo host all all ::1/128 trust >> /var/lib/pgsql/9.6/data/pg_hba.conf

#restarting postgres to take in hba rules
systemctl restart postgresql-9.6

#creating foreman and puppetdb users and db's
createuser --createrole puppetdb --username postgres
createdb --owner puppetdb puppetdb --username postgres
createuser --createrole foreman --username postgres
createdb --owner foreman foreman --username postgres

#install foreman from the repo
yum -y install foreman-installer

#running foreman installer with options
foreman-installer --foreman-admin-password=password --foreman-db-adapter=postgresql --foreman-db-database=foreman --foreman-db-host=localhost --foreman-db-manage=false --foreman-db-username=foreman  --foreman-db-password=password --foreman-db-port=5432 --foreman-configure-scl-repo=false --foreman-configure-epel-repo=false

#make puppet aware of puppetdb
/opt/puppetlabs/bin/puppet resource package puppetdb ensure=latest

#updating the puppetdb config
echo "subname = //127.0.0.1:5432/puppetdb" >> /etc/puppetlabs/puppetdb/conf.d/database.ini
echo "username = puppetdb" >> /etc/puppetlabs/puppetdb/conf.d/database.ini
echo "password = password" >> /etc/puppetlabs/puppetdb/conf.d/database.ini

#enable puppetdb and ensure running
/opt/puppetlabs/bin/puppet resource service puppetdb ensure=running enable=true

#configure foreman to work woth puppetdb
foreman-installer \
--enable-foreman-plugin-puppetdb \
--puppet-server-puppetdb-host=foreman.local \
--puppet-server-reports=foreman,puppetdb \
--puppet-server-storeconfigs-backend=puppetdb \
--foreman-plugin-puppetdb-address=https://foreman.local:8081/pdb/cmd/v1 \
--foreman-plugin-puppetdb-dashboard-address=http://localhost:8080/pdb/dashboard
