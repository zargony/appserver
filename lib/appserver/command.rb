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

      Server.initialize_dir(options) if command == 'init'

      server = Server.new(options)

      case command
        when 'init'
          server.write_configs
          puts 'Initialized appserver directory.'
          puts 'Wrote Monit and Nginx configuration snippets. Make sure to include them into'
          puts 'your system\'s Monit and Nginx configuration to become active.'

        when 'deploy'
          repository = server.repository(arguments[0])
          # TODO
          repository.install_hook

        when 'update'
          server.write_configs
          puts 'Wrote Monit and Nginx configuration snippets.'

        else
          raise UnknownCommandError
      end
    end
  end
end
