require File.expand_path(File.dirname(__FILE__) + '/../helpers')

Capistrano::Configuration.instance.load do
  # These are set to the same structure in shared <=> current
  set :normal_symlinks, %w(tmp log config/database.yml) unless exists?(:normal_symlinks)
  
  # Weird symlinks go somewhere else. Weird.
  set :weird_symlinks, { 'bundle' => 'vendor/bundle',
                         'pids'   => 'tmp/pids' } unless exists?(:weird_symlinks)

  namespace :symlinks do
    desc "|DarkRecipes| Make all the symlinks in a single run"
    task :make, :roles => :app, :except => { :no_release => true } do
      commands = normal_symlinks.map do |path|
        "rm -rf #{latest_release}/#{path} && \
         ln -s #{shared_path}/#{path} #{latest_release}/#{path}"
      end

      commands += weird_symlinks.map do |from, to|
        "rm -rf #{latest_release}/#{to} && \
         ln -s #{shared_path}/#{from} #{latest_release}/#{to}"
      end

      run <<-CMD
        cd #{latest_release} && #{commands.join(" && ")}
      CMD
    end
  end
end
