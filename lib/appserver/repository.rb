require 'fileutils'
require 'git'

module Appserver
  class InvalidRepositoryError < RuntimeError; end

  class Repository < Struct.new(:server_dir, :path)

    def initialize (server_dir, path, config)
      self.server_dir, self.path = server_dir, path.chomp('/')
      raise InvalidRepositoryError unless valid?
    end

    def name
      File.basename(path, '.git')
    end

    def app
      # The app for this repository (app of same name)
      @app ||= server_dir.app(name)
    end

    def valid?
      name && name != '' &&
      File.directory?(File.join(path, 'hooks')) &&
      File.directory?(File.join(path, 'refs'))
    end

    def update_hook
      File.join(path, 'hooks', 'update')
    end

    def install_hook
      deploy_cmd = server_dir.appserver_cmd('deploy')
      if !File.exist?(update_hook) || !File.executable?(update_hook)
        puts "Installing git update hook to repository #{path}..."
        Utils.safe_replace_file(update_hook) do |f|
          f.puts '#!/bin/sh'
          f.puts "#{deploy_cmd} #{path} $1 $3"
          f.chown File.stat(path).uid, File.stat(path).gid
          f.chmod 0755
        end
      elsif !File.readlines(update_hook).any? { |line| line =~ /^#{Regexp.escape(deploy_cmd)}/ }
        puts "Couldn't install update hook. Foreign hook script already present in repository #{path}!"
      else
        #puts "Hook already installed in repository #{path}"
      end
    end

    def deploy (ref = nil)
      # Choose a temporary build directory on the same filesystem so that it
      # can be easily renamed/moved to be the real application directory later
      build_path, old_path = "#{app.path}.new", "#{app.path}.old"
      begin
        # Check out the current code
        ref ||= app.branch
        checkout(build_path, ref)
        # Install gem bundle if a Gemfile exists
        install_bundle(build_path)

        # TODO: more deploy setup (write database config, ...)

        # Replace the current application directory with the newly built one
        FileUtils.rm_rf old_path
        FileUtils.mv app.path, old_path if File.exist?(app.path)
        FileUtils.mv build_path, app.path
      ensure
        # If anything broke and the build directory still exists, remove it
        FileUtils.rm_rf build_path
        # If anything broke and the app directory doesn't exist anymore, put the old directory in place
        FileUtils.mv old_path, app.path if !File.exist?(app.path) && File.exist?(old_path)
      end
    end

  protected

    def checkout (target_path, ref = 'master')
      # There seem to be two ways to "export" the tip of a branch from a repository
      # 1. clone the repository, check out the branch and remove the .git directory afterwards
      #system("git clone --depth 1 --branch master #{path} #{target_path} && rm -rf #{target_path}/.git")
      # 2. do a hard reset while pointing GIT_DIR to the repository and GIT_WORK_TREE to an empty dir
      #system("mkdir #{target_path} && git --git-dir=#{path} --work-tree=#{target_path} reset --hard #{branch}")
      git = Git.clone(path, target_path, :depth => 1)
      ref = git.revparse(ref)
      git.checkout(ref)
      Dir.chdir(target_path) do
        FileUtils.rm_rf '.git'
        Utils.safe_replace_file 'REVISION' do |f|
          f.puts ref
        end
      end
    end

    def install_bundle (target_path)
      Dir.chdir(target_path) do
        # Remove any .bundle subdirectory (it shouldn't be in the repository anyway)
        FileUtils.rm_rf '.bundle'
        # If there's a Gemfile, run "bundle install"
        if File.exist?('Gemfile')
          system "#{app.ruby} -S -- bundle install .bundle --without development test"
        end
      end
    end
  end
end
