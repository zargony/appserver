module Appserver
  class Repository
    class InvalidRepositoryError < RuntimeError; end

    attr_reader :server, :path

    def initialize (server, path)
      @server, @path = server, path.chomp('/')
    end
  end
end
