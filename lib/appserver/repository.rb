require 'fileutils'
require 'git'

module Appserver
  class InvalidRepositoryError < RuntimeError; end

  class Repository < Struct.new(:server, :dir)

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

    def update_hook
      File.join(dir, 'hooks', 'update')
    end

    def install_hook
      deploy_cmd = "#{File.expand_path($0)} -d #{server.dir} deploy"
      if !File.exist?(update_hook) || !File.executable?(update_hook)
        puts "Installing git update hook to repository #{dir}..."
        Utils.safe_replace_file(update_hook) do |f|
          f.puts '#!/bin/sh'
          f.puts "#{deploy_cmd} #{dir} $1 $3"
          f.chown File.stat(dir).uid, File.stat(dir).gid
          f.chmod 0755
        end
      elsif !File.readlines(update_hook).any? { |line| line =~ /^#{Regexp.escape(deploy_cmd)}/ }
        puts "Couldn't install update hook. Foreign hook script already present in repository #{dir}!"
      else
        #puts "Hook already installed in repository #{dir}"
      end
    end

    def deploy (ref = nil)
      # Choose a temporary build directory on the same filesystem so that it
      # can be easily renamed/moved to be the real application directory later
      build_dir, old_dir = "#{app.dir}.new", "#{app.dir}.old"
      begin
        # Check out the current code
        ref ||= app.branch
        checkout(build_dir, ref)
        # Install gem bundle if a Gemfile exists
        install_bundle(build_dir)

        # TODO: more deploy setup (write database config, ...)

        # Replace the current application directory with the newly built one
        FileUtils.rm_rf old_dir
        FileUtils.mv app.dir, old_dir if File.exist?(app.dir)
        FileUtils.mv build_dir, app.dir
      ensure
        # If anything broke and the build directory still exists, remove it
        FileUtils.rm_rf build_dir
        # If anything broke and the app directory doesn't exist anymore, put the old directory in place
        FileUtils.mv old_dir, app.dir if !File.exist?(app.dir) && File.exist?(old_dir)
      end
    end

  protected

    def expand_path (path)
      File.expand_path(path, dir)
    end

    def checkout (path, ref = 'master')
      # There seem to be two ways to "export" the tip of a branch from a repository
      # 1. clone the repository, check out the branch and remove the .git directory afterwards
      #system("git clone --depth 1 --branch master #{dir} #{path} && rm -rf #{path}/.git")
      # 2. do a hard reset while pointing GIT_DIR to the repository and GIT_WORK_TREE to an empty dir
      #system("mkdir #{path} && git --git-dir=#{dir} --work-tree=#{path} reset --hard #{branch}")
      git = Git.clone(dir, path, :depth => 1)
      ref = git.revparse(ref)
      git.checkout(ref)
      Dir.chdir(path) do
        FileUtils.rm_rf '.git'
        Utils.safe_replace_file 'REVISION' do |f|
          f.puts ref
        end
      end
    end

    def install_bundle (path)
      Dir.chdir(path) do
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
