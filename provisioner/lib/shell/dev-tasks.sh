#!/bin/bash

# Fix Permission on PHP/NGIX
#sudo sed -i 's/.*;listen.owner = www-data.*/listen.owner = www-data/' /etc/php5/fpm/pool.d/www.conf
#sudo sed -i 's/.*;listen.group = www-data.*/listen.group = www-data/' /etc/php5/fpm/pool.d/www.conf
#sudo sed -i 's/.*;listen.mode = www-data.*/listen.mode = www-data/' /etc/php5/fpm/pool.d/www.conf
#
#sudo service php5-fpm restart > /dev/null
# End fix

# enable MySQL for non-ssh remote
sudo sed -i 's/bind-address/#bind-address/' /etc/mysql/my.cnf
sudo sed -i 's/.*skip-external-locking.*/#skip-external-locking/g' /etc/mysql/my.cnf
sudo service mysql restart > /dev/null

mysql -uroot -plocal -e "GRANT ALL PRIVILEGES ON *.* TO 'dev'@'%' IDENTIFIED BY 'local' WITH GRANT OPTION; FLUSH PRIVILEGES"

# some tweaks
if [ ! -d /var/www ]; then
 sudo ln -s /vagrant /var/www
fi

#@ Fix SSH login
SSH_FIX_FILE="/etc/sudoers.d/root_ssh_agent"
if [ ! -f  $SSH_FIX_FILE ]
    then
    echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" > $SSH_FIX_FILE
    chmod 0440 $SSH_FIX_FILE
fi

# create this dev's dotenv file if it doesn't exist
if ! [[ -f /vagrant/.env ]]
then
   echo 'Creating dotenv file, verify setting in ./.env'
   cp /vagrant/.env.tmpl /vagrant/.env
fi

cd /vagrant
# Update/Install packages
echo "Updating gems"
bundle install > /dev/null

echo 'Updating composer'
composer update
echo "Done!"