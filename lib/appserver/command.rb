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
      server = Server.new(@options)
      case @command.to_sym
        when :init
          server.initialize_dir
          server.write_configs
          puts 'Initialized and wrote configuration files. You should now include the'
          puts 'Monit and Nginx configs into your system and deploy an application.'

        when :deploy
          # TODO
          raise 'Command not implemented yet'

        when :update
          server.write_configs
          puts 'Wrote configuration files.'

        else
          raise UnknownCommandError
      end
    end
  end
end
