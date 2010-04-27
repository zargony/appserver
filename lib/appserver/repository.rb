module Appserver
  class Repository < Struct.new(:server, :path)
    class InvalidRepositoryError < RuntimeError; end

    include Utils

    def initialize (server, path, config)
      self.server, self.path = server, path.chomp('/')
      raise InvalidRepositoryError unless valid?
    end

    def name
      File.basename(path, '.git')
    end

    def valid?
      File.directory?(File.join(path, 'hooks')) && File.directory?(File.join(path, 'refs'))
    end

    def post_receive_hook
      File.join(path, 'hooks', 'post-receive')
    end

    def install_hook
      deploy_cmd = "#{File.expand_path($0)} -d #{File.expand_path(server.dir)} deploy #{File.expand_path(path)}"
      if !File.exist?(post_receive_hook) || !File.executable?(post_receive_hook)
        puts "Installing git post-receive hook to repository #{path}..."
        safe_replace_file(post_receive_hook) do |f|
          f.puts '#!/bin/sh'
          f.puts deploy_cmd
          f.chown File.stat(path).uid, File.stat(path).gid
          f.chmod 0755
        end
      elsif !File.readlines(post_receive_hook).any? { |line| line =~ /^#{Regexp.escape(deploy_cmd)}/ }
        puts "Couldn't install post-receive hook. Foreign hook script already present in repository #{path}!"
      else
        #puts "Hook already installed in repository #{path}"
      end
    end
  end
end
