module Appserver
  class UnknownCommandError < RuntimeError
  end

  class Command
    def self.run! (command, arguments, options = {})
      new(command, arguments, options).run!
    end

    def initialize (command, arguments, options = {})
      @command, @arguments, @options = command, arguments, options
    end

    def run!
      case @command.to_sym
        when :init
          # TODO
          raise 'Command not implemented yet'

        when :deploy
          # TODO
          raise 'Command not implemented yet'

        when :update
          # TODO
          raise 'Command not implemented yet'

        else
          raise UnknownCommandError
      end
    end
  end
end
