#!/bin/bash

OS=$(/bin/bash /vagrant/provisioner/lib/shell/os-detect.sh ID)
CODENAME=$(/bin/bash /vagrant/provisioner/lib/shell/os-detect.sh CODENAME)

PUPPET_LOCATION=( $( /bin/cat /vagrant/provisioner/.protobox/config ) )
PUPPET_DATA="/vagrant/provisioner/$PUPPET_LOCATION"
PROTOBOX_LOGO=/vagrant/provisioner/lib/shell/logo.txt

# process arguments
while getopts ":a:" opt; do
  case $opt in
    a)
      PARAMS="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done



if [[ "$PARAMS" == "" ]]; then
    echo "ERROR: Options -a require arguments." >&2
    exit 1
fi

# start protobox
if [[ ! -d /vagrant/provisioner/.protobox ]]; then
    mkdir /vagrant/provisioner/.protobox
    echo "Created directory /vagrant/provisioner/.protobox"
fi

if [[ ! -f /vagrant/provisioner/.protobox/initial-update ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running initial-setup apt-get update"
        apt-get update -y >/dev/null 2>&1
        echo "Finished running initial-setup apt-get update"

        touch /vagrant/provisioner/.protobox/initial-update

    elif [[ "$OS" == 'centos' ]]; then
        echo "Running initial-setup yum update"
        yum update -y >/dev/null 2>&1
        echo "Finished running initial-setup yum update"

        echo "Installing basic development tools (CentOS)"
        yum -y groupinstall "Development Tools" >/dev/null 2>&1
        echo "Finished installing basic development tools (CentOS)"

        touch /vagrant/provisioner/.protobox/initial-update
    fi
fi

if [[ "$OS" == 'ubuntu' && ("$CODENAME" == 'lucid' || "$CODENAME" == 'precise') && ! -f /vagrant/provisioner/.protobox/ubuntu-required-libraries ]]; then
    echo 'Installing basic curl packages (Ubuntu only)'
    apt-get install -y libcurl3 libcurl4-gnutls-dev >/dev/null 2>&1
    echo 'Finished installing basic curl packages (Ubuntu only)'

    touch /vagrant/provisioner/.protobox/ubuntu-required-libraries
fi

if [[ ! -f /vagrant/provisioner/.protobox/python-software-properties ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running python-software-properties"
        apt-get -y install python-software-properties >/dev/null 2>&1
        echo "Finished python-software-properties"

        touch /vagrant/provisioner/.protobox/python-software-properties
    elif [ "$OS" == 'centos' ]; then


        touch /vagrant/provisioner/.protobox/python-software-properties
    fi
fi

if [[ ! -f /vagrant/provisioner/.protobox/install-pip ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Installing python-pip"
        apt-get -y install python-pip python-dev >/dev/null 2>&1
        echo "Finished python-pip"

        touch /vagrant/provisioner/.protobox/install-pip

    elif [ "$OS" == 'centos' ]; then
        #yum install install python-pip python-devel

        touch /vagrant/provisioner/.protobox/install-pip
    fi
fi

if [[ ! -f /vagrant/provisioner/.protobox/install-ansible ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running pip install ansible"
        pip install ansible >/dev/null 2>&1
        echo "Finished pip install ansible"

        touch /vagrant/provisioner/.protobox/install-ansible

    elif [ "$OS" == 'centos' ]; then
        #pip install ansible

        touch /vagrant/provisioner/.protobox/install-ansible
    fi
fi

if [[ ! -f /vagrant/provisioner/.protobox/install-ansible-hosts ]]; then

    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Installing ansible hosts"
        mkdir -p /etc/ansible

        # Setup hosts
        touch /etc/ansible/hosts
        #echo "localhost" > /etc/ansible/hosts
        #echo "127.0.0.1" > /etc/ansible/hosts
        echo "localhost ansible_connection=local" > /etc/ansible/hosts

        # Setup config
        cp /vagrant/provisioner/lib/ansible/ansible.cfg /etc/ansible/ansible.cfg

        touch /vagrant/provisioner/.protobox/install-ansible-hosts

    elif [ "$OS" == 'centos' ]; then

        touch /vagrant/provisioner/.protobox/install-ansible-hosts
    fi
fi

# set up git-fat
echo "Running pip install git-fat"
pip install git-fat >/dev/null 2>&1
echo "Finished pip install git-fat"


# Run ansible playbook
echo "Running ansible-playbook $PARAMS"
sh -c "ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false PYTHONUNBUFFERED=1 ansible-playbook $PARAMS"
echo "Finished ansible-playbook"
