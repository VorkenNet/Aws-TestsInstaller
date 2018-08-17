#!/bin/bash
# Aggiorna il sistema
sudo yum update -y
# Crea il filesystem per la nuova partizione
sudo mkfs -t ext4 /dev/xvdb
# Crea la directory per il mountPoint
mkdir /var/lib/mysql
# Modifica il file Fstab
echo /dev/xvdb /var/lib/mysql ext4 noatime 0 0 | sudo tee -a /etc/fstab > /dev/null
# Monta la partizione
sudo mount /var/lib/mysql
# Installa MariaDB via Yum
sudo yum install mariadb-server -y
# Crea i file di mysql
sudo mysql_install_db
# Modifica i permessi sui file crati
sudo chown -R mysql:mysql /var/lib/mysql
# Finisce l'installazione utilizzando i permessi corretti
sudo mysql_install_db
# Attiva il servizio Mysql
sudo systemctl start mariadb
# Attiva MariaDB al boot
sudo systemctl enable mariadb
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('test01') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param
#
# Crea e configura il DB per il Test
#
echo "> Creating DataBases\n"
# Crea 25 DB
for i in {1..25}; do
   mysql -u root -ptest01 -Bse "CREATE DATABASE IF NOT EXISTS myTestDB$i CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
done
# Crea la Tabelle
echo "> Creating Tables\n"
for i in {1..25}; do
  mysql -u root -ptest01 -Bse "CREATE TABLE IF NOT EXISTS myTestDB$i.myTable(
    Id int(11) NOT NULL auto_increment,
    myTimeStamp timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
    rand int(11) NOT NULL,
    PRIMARY KEY  (Id)
  ) ;"
done;
# Inserisce le prime 10 entries per ogni tabella
echo "> Populating Tables\n"
for i in {1..25}; do
  for x in {1..10}; do mysql -u root -ptest01 -Bse "INSERT INTO myTestDB$i.myTable (Id, myTimeStamp, rand) VALUES (NULL, CURRENT_TIMESTAMP, '$RANDOM');"; done
done
#
# Crea i Cron
#
echo "> Creating Cron\n"
for i in {1..25}; do
  echo "for i in {1..25}; do mysql -u root -ptest01 -Bse \"INSERT INTO myTestDB$i.myTable (Id, myTimeStamp, rand) VALUES (NULL, CURRENT_TIMESTAMP, '\$RANDOM');\"; done" | sudo tee -a /home/ec2-user/myTestCron$i.sh > /dev/null
  echo "mysql -u root -ptest01 -Bse \"delete from myTestDB$i.myTable order by Id asc limit 25\"" | sudo tee -a /home/ec2-user/myTestCron$i.sh > /dev/null
done
#
# Attiva il Cron
#
echo "> Activating Cron\n"
#write out current crontab
sudo crontab -l | sudo tee -a mycron > /dev/null
for i in {1..25}; do
  # echo new cron into cron file
  echo " * * * * * sh /home/ec2-user/myTestCron$i.sh" | sudo tee -a mycron > /dev/null
done
#install new cron file
sudo crontab mycron
sudo rm -f mycron
echo "> Done!\n"
