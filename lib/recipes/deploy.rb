require File.expand_path(File.dirname(__FILE__) + '/../helpers')

Capistrano::Configuration.instance.load do
  set :shared_children, %w(system log pids config)
  
  namespace :deploy do
    desc "|DarkRecipes| Deploy it, github-style."
    task :default, :roles => :app, :except => { :no_release => true } do
      update
      restart
    end
    
    desc "|DarkRecipes| Destroys everything"
    task :seppuku, :roles => :app, :except => { :no_release => true } do
      run "rm -rf #{current_path}; rm -rf #{shared_path}"
    end
    
    desc "|DarkRecipes| Create shared dirs"
    task :setup_dirs, :roles => :app, :except => { :no_release => true } do
      commands = shared_dirs.map do |path|
        "mkdir -p #{shared_path}/#{path}"
      end
      run commands.join(" && ")
    end
    
    desc "|DarkRecipes| Uploads your local config.yml to the server"
    task :configure, :roles => :app, :except => { :no_release => true } do
      generate_config('config/config.yml', "#{shared_path}/config/config.yml")
    end
    
    desc "|DarkRecipes| Setup a GitHub-style deployment."
    task :setup, :roles => :app, :except => { :no_release => true } do
      run "rm -rf #{current_path}"
      setup_dirs
      run "git clone #{repository} #{current_path}"
    end
    
    desc "|DarkRecipes| Update the deployed code."
    task :update_code, :roles => :app, :except => { :no_release => true } do
      run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    end

    desc "|DarkRecipes| Alias for symlinks:make"
    task :symlink, :roles => :app, :except => { :no_release => true } do
      symlinks.make
    end
    
    desc "|DarkRecipes| Remote run for rake db:migrate"
    task :migrate, :roles => :app, :except => { :no_release => true } do
      run "cd #{current_path}; bundle exec rake RAILS_ENV=#{rails_env} db:migrate"
    end

    desc "|DarkRecipes| [Obsolete] Nothing to cleanup when using reset --hard on git"
    task :cleanup, :roles => :app, :except => { :no_release => true } do
      #nothing to cleanup, we're not working with 'releases'
      puts "Nothing to cleanup, yay!"
    end

    namespace :rollback do
      desc "|DarkRecipes| Rollback , :except => { :no_release => true }a single commit."
      task :default, :roles => :app, :except => { :no_release => true } do
        set :branch, "HEAD^"
        deploy.default
      end    
    end

    desc <<-DESC
      |DarkRecipes| Restarts your application. This depends heavily on what server you're running. 
      If you are running Phusion Passenger, you can explicitly set the server type:
      
        set :server, :passenger
          
      ...which will touch tmp/restart.txt, a file monitored by Passenger.

      If you are running Unicorn, you can set:
      
        set :server, :unicorn
      
      ...which will use unicorn signals for restarting its workers.

      Otherwise, this command will call the script/process/reaper \
      script under the current path.
      
      If you are running with Unicorn, you can set the server type as well:
      
      set :server, :unicorn

      By default, this will be |DarkRecipes| d via sudo as the `app' user. If \
      you wish to run it as a different user, set the :runner variable to \
      that user. If you are in an environment where you can't use sudo, set \
      the :use_sudo variable to false:

      set :use_sudo, false
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      if exists?(:app_server)
        case fetch(:app_server).to_s.downcase
          when 'passenger'
            passenger.bounce
          when 'unicorn'
            is_using('god', :monitorer) ? god.restart.app : unicorn.restart
        end
      else
        puts "Dunno how to restart your internets! kthx!"
      end
    end
  end
end
