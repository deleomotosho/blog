set :stage, :production

# Simple Role Syntax
# ==================
#role :app, %w{deploy@example.com}
#role :web, %w{deploy@example.com}
#role :db,  %w{deploy@example.com}

# Extended Server Syntax
# ======================
server 'dele.webfactional.com', user: 'dele', roles: %w{web app db}

set :log_level, :debug
set :deploy_to, "/home/dele/webapps/thoughtsatire"
# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#

namespace :deploy do
    task :search_and_replace_db do
      on roles(:app) do
        execute "cd #{release_path} && php55 ./vendor/wp-cli/wp-cli/bin/wp search-replace 'thoughtsatire.dev' 'thoughtsatire.com'"
      end
    end

    after :updated, 'deploy:search_and_replace_db'

end

fetch(:default_env).merge!(wp_env: :production)

