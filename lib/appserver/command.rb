module Appserver
  class UnknownCommandError < RuntimeError; end

  class Command
    def self.run! (command, arguments, options = {})
      new(command, arguments, options).run!
    end

    def initialize (command, arguments, options = {})
      @command, @arguments, @options = command, arguments, options
    end

    def run!
      server = Server.new(@options.delete(:dir) || Dir.pwd, @options)

      case @command.to_sym
        when :init
          server.initialize_dir
          puts 'Initialized server directory by creating appserver.yml.'
          server.write_configs
          puts 'Wrote Monit and Nginx configuration snippets. Make sure to include them into'
          puts 'your system\'s Monit and Nginx configuration to become active.'

        when :deploy
          repository = server.repository(@arguments[0])
          # TODO

        when :update
          server.write_configs
          puts 'Wrote Monit and Nginx configuration snippets.'

        else
          raise UnknownCommandError
      end
    end
  end
end
