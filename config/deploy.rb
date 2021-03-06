require 'rvm/capistrano'
require 'bundler/capistrano'
set :user, 'alex'
set :domain, 'teslablog.ru'
set :applicationdir, "/var/www/custom"

set :scm, 'git'
set :repository,  "https://github.com/alleycat-at-git/custom.git"
#set :git_enable_submodules, 1 # if you have vendored rails
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true

# roles (servers)
role :web, domain
role :app, domain
role :db,  domain, :primary => true

# deploy config
set :deploy_to, applicationdir
set :deploy_via, :export
#set :use_sudo, false
set :ssh_options, { :forward_agent => true }

# additional settings
default_run_options[:pty] = true  # Forgo errors when deploying from windows

before "deploy", "deploy:sudo"
before "deploy:cleanup", "deploy:no_sudo_prompt"
before "deploy:cleanup", "deploy:sudo"
after "deploy:cleanup", "deploy:sudo_prompt"
after "deploy", "deploy:migrate"
before 'deploy:assets:precompile', 'deploy:symlink_db'
# after 'deploy:migrate', 'deploy:generate_sitemap'

set :default_environment, {
    PG_USER: ENV["PG_USER"],
    PG_PASS: ENV["PG_PASS"]
}

namespace :deploy do

  task :start do run "sudo /etc/init.d/thin start" end

  task :stop do run "sudo /etc/init.d/thin stop" end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} /etc/init.d/thin restart"
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Symlinks db and images"
  task :symlink_db, :roles => :app do
    # run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
    run "rm -rf #{release_path}/public/images"
    run "ln -nfs #{deploy_to}/shared/images #{release_path}/public/images"
  end

  desc "Promts for sudo pwd in advance"
  task :sudo, :roles => :app do
    run "#{try_sudo} ls"
  end

  task :no_sudo_prompt, :roles => :app do
    set :sudo_prompt, ""
  end

  task :sudo_prompt, :roles => :app do
    set :sudo_prompt, "sudo password: "
  end


end