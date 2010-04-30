require 'socket'
require 'tempfile'

module Appserver
  module Utils
    def self.included (base)
      base.class_eval do
        extend Methods
        include Methods
      end
    end

    module Methods
      def find_in_path (name)
        ENV['PATH'].split(':').find { |path| File.exist?(File.join(path, name)) }
      end

      def system_hostname
        Socket.gethostname
      end

      def system_domainname
        system_hostname.sub(/^[^.]+\./, '')
      end

      def safe_replace_file (filename)
        tempfile = Tempfile.new(File.basename(filename) + '.', File.dirname(filename))
        if File.exist?(filename)
          tempfile.chown(File.stat(filename).uid, File.stat(filename).gid)
          tempfile.chmod(File.stat(filename).mode)
        end
        yield tempfile
        tempfile.close
        File.unlink(filename) if File.exist?(filename)
        File.rename(tempfile, filename)
      end

      def symbolize_keys (hash)
        hash.inject({}) do |memo, (key, value)|
          value = symbolize_keys(value) if Hash === value
          memo[key.to_sym] = value
          memo
        end
      end
    end
  end
end
