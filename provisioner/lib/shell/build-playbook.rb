def build_playbook(yaml, protobox_dir)
  protobox_playbook = protobox_dir + '/playbook'

  out = []

  play = {}
  play['name'] = 'Core'
  play['hosts'] = 'all'
  #play['sudo'] = true
  #play['sudo_user'] = 'root'
  play['vars_files'] = ['{{ protobox_config }}']
  
  entries = []

  # Common
  entries << { "role" => "common" }

  # Server
  if !yaml['server'].nil?
    entries << { "role" => "server", "when" => "server is defined" }
  end
  
  # Shell - zsh
  if !yaml['zsh'].nil? and yaml['zsh']['install'].to_i == 1
    entries << { "role" => "zsh", "when" => "zsh is defined and zsh.install == 1" }
  end
 
 # Web server - nginx
  if !yaml['nginx'].nil? and yaml['nginx']['install'].to_i == 1
    entries << { "role" => "nginx", "when" => "nginx is defined and nginx.install == 1" }
  end

  # Web server - apache
  if !yaml['apache'].nil? and yaml['apache']['install'].to_i == 1
    entries << { "role" => "apache", "when" => "apache is defined and apache.install == 1" }
  end

  # Languages - ruby
  if !yaml['ruby'].nil? and yaml['ruby']['install'].to_i == 1
    entries << { "role" => "ruby", "when" => "ruby is defined and ruby.install == 1" }
  end

   # Languages - python
  if !yaml['python'].nil? and yaml['python']['install'].to_i == 1
    entries << { "role" => "python", "when" => "python is defined and python.install == 1" }
  end

  # Database - mysql
  if !yaml['mysql'].nil? and yaml['mysql']['install'].to_i == 1
    entries << { "role" => "mysql", "when" => "mysql is defined and mysql.install == 1" }
  end

  # Database - mariadb
  if !yaml['mariadb'].nil? and yaml['mariadb']['install'].to_i == 1
     entries << { "role" => "mariadb", "when" => "mariadb is defined and mariadb.install == 1" }
  end

  # Languages - php
  if !yaml['php'].nil? and yaml['php']['install'].to_i == 1
    entries << { "role" => "php", "when" => "php is defined and php.install == 1" }
  end

  # Languages - node
  if !yaml['node'].nil? and yaml['node']['install'].to_i == 1
    entries << { "role" => "node", "when" => "node is defined and node.install == 1" }
  end

 

  # Queues / Messaging - beanstalkd
  if !yaml['beanstalkd'].nil? and yaml['beanstalkd']['install'].to_i == 1
   entries << { "role" => "beanstalkd", "when" => "beanstalkd is defined and beanstalkd.install == 1" }
  end

  # Tools - ngrok
  if !yaml['ngrok'].nil? and yaml['ngrok']['install'].to_i == 1
    entries << { "role" => "ngrok", "when" => "ngrok is defined and ngrok.install == 1" }
  end

  # Tools - memcached
  if !yaml['memcached'].nil? and yaml['memcached']['install'].to_i == 1
    entries << { "role" => "memcached", "when" => "memcached is defined and memcached.install == 1" }
  end

  # In-Memory Store - redis
  if !yaml['redis'].nil? and yaml['redis']['install'].to_i == 1
   entries << { "role" => "redis", "when" => "redis is defined and redis.install == 1" }
  end

  # Web extras - varnish
  if !yaml['varnish'].nil? and yaml['varnish']['install'].to_i == 1
    entries << { "role" => "varnish", "when" => "varnish is defined and varnish.install == 1" }
  end
    # Web extras - varnish
    if !yaml['varnish'].nil? and yaml['varnish']['install'].to_i == 1
      entries << { "role" => "varnish", "when" => "varnish is defined and varnish.install == 1" }
    end
  play['roles'] = entries

  out << play

  # Dump out the contents
  File.open(protobox_playbook, 'w') do |file|
    YAML::dump(out, file)
  end

  return true
end
