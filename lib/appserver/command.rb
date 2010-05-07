module Appserver
  class UnknownCommandError < RuntimeError; end

  class Command
    def self.run! (*args)
      new(*args).run!
    end

    attr_reader :command, :arguments, :options

    def initialize (command, arguments, options = {})
      @command, @arguments, @options = command, arguments, options
    end

    def run!
      Dir.chdir(options[:dir]) if options[:dir]

      ServerDir.initialize_dir(options) if command == 'init'

      server = ServerDir.new(options)

      case command
        when 'init'
          server.write_configs
          puts 'Initialized appserver directory.'
          puts 'Wrote configuration snippets. Make sure to include them into your'
          puts 'system\'s Monit/Nginx/Logrotate configuration to become active.'

        when 'deploy'
          repository = server.repository(arguments[0])
          repository.install_hook
          # Second and third arguments are used by git update hooks and contain
          # the ref name and the new ref that just have been updated
          ref = repository.app.branch
          if arguments[1] && arguments[2]
            return unless arguments[1] =~ %r(refs/heads/#{ref})
            ref = arguments[2]
          end
          puts 'Deploying application...'
          repository.deploy(ref)
          puts 'Done.'

        when 'update'
          server.write_configs
          puts 'Wrote configuration snippets.'

        else
          raise UnknownCommandError
      end
    end
  end
end
