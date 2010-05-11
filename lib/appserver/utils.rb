require 'socket'
require 'tempfile'

module Appserver
  module Utils

    class << self
      def find_in_path (name)
        ENV['PATH'].split(':').find { |path| File.exist?(File.join(path, name)) }
      end

      def system_hostname
        Socket.gethostname
      end

      def system_domainname
        system_hostname.sub(/^[^.]+\./, '')
      end

      def number_of_cpus
        if File.exist?('/proc/cpuinfo')
          File.readlines('/proc/cpuinfo').grep(/^processor\s+:\s+\d+/).size
        end
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
        File.rename(tempfile.path, filename)
      end
    end
  end
end
