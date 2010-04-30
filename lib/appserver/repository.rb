require 'fileutils'
require 'git'

module Appserver
  class Repository < Struct.new(:server, :dir)
    class InvalidRepositoryError < RuntimeError; end

    include Utils

    def initialize (server, dir, config)
      self.server, self.dir = server, dir.chomp('/')
      raise InvalidRepositoryError unless valid?
    end

    def name
      File.basename(dir, '.git')
    end

    def app
      # The app for this repository (app of same name)
      @app ||= server.app(name)
    end

    def valid?
      name && name != '' &&
      File.directory?(File.join(dir, 'hooks')) &&
      File.directory?(File.join(dir, 'refs'))
    end

    def post_receive_hook
      File.join(dir, 'hooks', 'post-receive')
    end

    def install_hook
      deploy_cmd = "#{File.expand_path($0)} -d #{server.dir} deploy #{dir}"
      if !File.exist?(post_receive_hook) || !File.executable?(post_receive_hook)
        puts "Installing git post-receive hook to repository #{dir}..."
        safe_replace_file(post_receive_hook) do |f|
          f.puts '#!/bin/sh'
          f.puts deploy_cmd
          f.chown File.stat(dir).uid, File.stat(dir).gid
          f.chmod 0755
        end
      elsif !File.readlines(post_receive_hook).any? { |line| line =~ /^#{Regexp.escape(deploy_cmd)}/ }
        puts "Couldn't install post-receive hook. Foreign hook script already present in repository #{dir}!"
      else
        #puts "Hook already installed in repository #{dir}"
      end
    end

    def deploy
      # Choose a temporary build directory on the same filesystem so that it
      # can be easily renamed/moved to be the real application directory later
      build_dir, old_dir = "#{app.dir}.new", "#{app.dir}.old"
      begin
        # Check out the current code
        checkout(build_dir, app.branch)
        # Install gem bundle if a Gemfile exists
        install_bundle(build_dir)

        # TODO: more deploy setup (write database config, ...)

        # Replace the current application directory with the newly built one
        FileUtils.rm_rf old_dir
        FileUtils.mv app.dir, old_dir if Dir.exist?(app.dir)
        FileUtils.mv build_dir, app.dir

        # TODO: update monit/nginx configs (needs root, use monit?)
        # TODO: restart instances (needs root, use monit?)
        # TODO: remove old_dir *after* restart succeeded, maybe revert to old_dir on failure

      ensure
        # If anything broke and the build directory still exists, remove it
        FileUtils.rm_rf build_dir
        # If anything broke and the app directory doesn't exist anymore, put the old directory in place
        FileUtils.mv old_dir, app.dir if !Dir.exist?(app.dir) && Dir.exist?(old_dir)
      end
    end

  protected

    def expand_path (path)
      File.expand_path(path, dir)
    end

    def checkout (path, branch = 'master')
      # There seem to be two ways to "export" the tip of a branch from a repository
      # 1. clone the repository, check out the branch and remove the .git directory afterwards
      #system("git clone --depth 1 --branch master #{dir} #{path} && rm -rf #{path}/.git")
      # 2. do a hard reset while pointing GIT_DIR to the repository and GIT_WORK_TREE to an empty dir
      #system("mkdir #{path} && git --git-dir=#{dir} --work-tree=#{path} reset --hard #{branch}")

      # We use the Git.export from the git gem here, which uses the first
      # method (and handles errors more nicely than a uing system())
      Git.export(dir, path, :branch => branch)
    end

    def install_bundle (path)
      bundle_path = File.join(path, '.bundle')
      gemfile = File.join(path, 'Gemfile')
      # Remove any .bundle subdirectory (it shouldn't be in the repository anyway)
      FileUtils.rm_rf bundle_path
      # If there's a Gemfile, change to the application directory and run "bundler install"
      return unless File.exist?(gemfile)
      Dir.chdir(path) do
        system Gem.bin_path('bundler', 'bundle'), 'install', bundle_path
      end
    end
  end
end
