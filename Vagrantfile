# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require File.expand_path(File.dirname(__FILE__) + '/provisioner/lib/shell/build-playbook')
require File.expand_path(File.dirname(__FILE__) + '/provisioner/lib/shell/build-dashboard')

dir = Dir.pwd
vagrant_dir = File.expand_path(File.dirname(__FILE__))
protobox_dir = vagrant_dir + '/provisioner/.protobox'
protobox_boot = protobox_dir + '/config'

cli_file = vagrant_dir + '/provisioner/.protobox_cli'
cli_version = File.open(cli_file) {|f| f.readline}

# Check vagrant version
if Vagrant::VERSION < "1.5.0"
  puts "Please upgrade to vagrant 1.5+: "
  puts "http://www.vagrantup.com/downloads.html"
  puts 
  exit
end

# check for host-manager plugins
if !Vagrant.has_plugin?('vagrant-hostsupdater')
   puts "vagrant-hostsupdater is missing, run the following: "
   puts
   puts "vagrant plugin install vagrant-hostsupdater"
   puts
   exit
end

# SSH
id_rsa_ssh_key = File.read(File.join(Dir.home, ".ssh", "id_rsa"))
id_rsa_ssh_key_pub = File.read(File.join(Dir.home, ".ssh", "id_rsa.pub"))


# Create protobox dir if it doesn't exist
if !File.directory?(protobox_dir)
  Dir.mkdir(protobox_dir)
end

# Check if protobox boot file exists, if it doesn't create it here
if !File.file?(protobox_boot)
  File.open(protobox_boot, 'w') do |file|
    file.write('provisioner/data/config/common.yml')
  end
end

# Check for boot file
if !File.file?(protobox_boot)
  puts "Boot file is missing: #{protobox_boot}\n"
  exit
end

# Open config file location
vagrant_file = File.open(protobox_boot) {|f| f.readline.chomp}

# Check for missing data file
if !File.file?(vagrant_dir + '/' + vagrant_file)
  puts "Data file is missing: #{vagrant_dir}/#{vagrant_file}\n"
  puts "You may need to switch your config: ruby protobox switch [config]"
  exit
end

# Load settings into memory
settings = YAML.load_file(vagrant_dir + '/' + vagrant_file)

# Build the playbook
playbook = build_playbook(settings, protobox_dir);

# Build the dashboard
dashboard = build_dashboard(settings, protobox_dir);

# Start vagrant configuration
Vagrant.configure("2") do |config|

  # Store the current version of Vagrant for use in conditionals when dealing
  # with possible backward compatible issues.
  vagrant_version = Vagrant::VERSION.sub(/^v/, '')

  # Vagrant settings variable
  vagrant_vm = 'vagrant'

  # Check for box settings
  if settings[vagrant_vm].nil? or settings[vagrant_vm].nil?
    puts "Invalid yml data: #{vagrant_file}\n"
    exit
  end

  if !settings[vagrant_vm]['vm']['box'].nil?
    config.vm.box = settings[vagrant_vm]['vm']['box']
  end

  # Box URL
  if !settings[vagrant_vm]['vm']['box_url'].nil?
    config.vm.box_url = settings[vagrant_vm]['vm']['box_url']
  end

  # Box version
  if !settings[vagrant_vm]['vm']['box_version'].nil?
    config.vm.box_version = settings[vagrant_vm]['vm']['box_version']
  end

  # Box updates
  if !settings[vagrant_vm]['vm']['box_check_update'].nil?
    config.vm.box_check_update = settings[vagrant_vm]['vm']['box_check_update']
  end

  config.vm.provider 'parallels' do |v, override|
     override.vm.box = 'parallels/ubuntu-12.04'
     override.vm.box_check_update = true

     # Can be running at background, see https://github.com/Parallels/vagrant-parallels/issues/39
     v.customize ['set', :id, '--on-window-close', 'keep-running']
  end

  # Hostname
  if !settings[vagrant_vm]['vm']['hostname'].nil?
    config.vm.hostname = settings[vagrant_vm]['vm']['hostname']
  end

  # Ports and IP Address
  if !settings[vagrant_vm]['vm']['usable_port_range'].nil?
    ends = settings[vagrant_vm]['vm']['usable_port_range'].to_s.split('..').map{|d| Integer(d)}
    config.vm.usable_port_range = (ends[0]..ends[1])
  end

  # network IP
  config.vm.network :private_network, ip: settings[vagrant_vm]['vm']['network']['private_network'].to_s

  # Forwarded ports
  settings[vagrant_vm]['vm']['network']['forwarded_port'].each do |item, port|
    if !port['guest'].nil? and 
       !port['host'].nil? and 
       !port['guest'].empty? and 
       !port['host'].empty?
      config.vm.network :forwarded_port, guest: Integer(port['guest']), host: Integer(port['host'])
    end
  end

  # Synced Folders
  config.vm.synced_folder "./", "/var/www",  
    :nfs => false, 
    :create => true,
    :owner => 'vagrant', 
    :group => 'www-data', 
    :mount_option => ["dmode=775","fmode=775"]

 config.vm.synced_folder "../", "/vendors",  
    :nfs => false, 
    :create => true,
    :owner => 'vagrant', 
    :group => 'www-data', 
    :mount_option => ["dmode=775","fmode=775"]


  # Provider Configuration
  if settings[vagrant_vm]['vm'].has_key?("provider") and !settings[vagrant_vm]['vm']['provider'].nil?

    # Loop through providers
    settings[vagrant_vm]['vm']['provider'].each do |prov, options|
      # Set specific provider info
      config.vm.provider prov.to_sym do |params|
        # Loop through provider options
        options.each do |type, values|
          # Check if option has suboptions
          if values.is_a?(Hash) 
            values.each do |key, value|
              params.customize [type, :id, "--#{key}", value]
            end
          # Set key=value options
          else
            params.send("#{type}=", values)
          end
        end
      end
    end
  end


  # Ansible Provisioning
  if settings[vagrant_vm]['vm']['provision'].has_key?("ansible")
    ansible = settings[vagrant_vm]['vm']['provision']['ansible']

    if (ansible['playbook'] == "default" or ansible['playbook'] == "ansible/site.yml") and playbook
      playbook_path = "/vagrant/provisioner/.protobox/playbook"
    else
      playbook_path = "/vagrant/provisioner/" + ansible['playbook']
    end

    params = Array.new
    params << playbook_path

    if !ansible['inventory'].nil?
      params << "-i \\\"" + ansible['inventory'] + "\\\""
    end

    if !ansible['verbose'].nil?
      if ansible['verbose'] == 'vv' or ansible['verbose'] == 'vvv' or ansible['verbose'] == 'vvvv'
        params << "-" + ansible['verbose']
      else
        params << "--verbose"
      end
    end

    params << "--connection=local"

    if !ansible['extra_vars'].nil?
      extra_vars = ansible['extra_vars']
    else
      extra_vars = Hash.new
    end

    extra_vars['protobox_env'] = "vagrant"
    extra_vars['protobox_config'] = "/vagrant/" + vagrant_file

    params << "--extra-vars=\\\"" + extra_vars.map{|k,v| "#{k}=#{v}"}.join(" ").gsub("\"","\\\\\"") + "\\\"" unless extra_vars.empty?

    config.vm.provision :shell, :path => "provisioner/lib/shell/initial-setup.sh", :args => "-a \"" + params.join(" ") + "\"", :keep_color => true
  end 

   # SSH Configuration
   settings[vagrant_vm]['ssh'].each do |item, value|
     if !value.nil?
       config.ssh.send("#{item}=", value)
     end
   end

  # Running Custom Shells
   config.vm.provision :shell, :inline => "echo -e '#{File.read("#{Dir.home}/.gitconfig")}' > '/home/vagrant/.gitconfig'"
   config.vm.provision :shell, :path => "provisioner/lib/shell/dev-tasks.sh"


  # Vagrant Configuration
  settings[vagrant_vm]['vagrant'].each do |item, value|
    if !value.nil?
      config.vagrant.send("#{item}=", /:(.+)/ =~ value ? $1.to_sym : value)
    end
  end
end
