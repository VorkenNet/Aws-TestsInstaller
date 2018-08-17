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
echo "> Done!"
