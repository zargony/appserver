module Appserver
  class Nginx < Struct.new(:server_dir)
    include Utils

    def self.write_config (server_dir)
      new(server_dir).write_config
    end

    def initialize (server_dir)
      self.server_dir = server_dir
    end

    def write_config
      safe_replace_file(server_dir.nginx_conf) do |f|
        f.puts "# Nginx configuration automagically generated by the \"appserver\" gem using"
        f.puts "# the appserver directory config #{server_dir.config_file}"
        f.puts "# Include this file into your system's nginx.conf (using an include statement"
        f.puts "# inside a http statement) to use it. See http://github.com/zargony/appserver"
        f.puts "# for details."
        # The default server always responds with 403 Forbidden
        f.puts "server {"
        f.puts "  listen 80 default;"
        f.puts "  server_name _;"
        f.puts "  deny all;"
        f.puts "}"
        # Add application-specific Nginx configuration
        server_dir.apps.each do |app|
          app.write_nginx_config(f)
        end
      end
    end
  end
end