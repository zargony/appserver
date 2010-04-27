require File.expand_path('../../appserver', __FILE__)
app_dir = File.expand_path('..', Unicorn::HttpServer::START_CTX[:argv][-1])
app = Appserver::Server.new(File.dirname(app_dir)).app(File.basename(app_dir))

working_directory app.dir
stderr_path app.server_log
stdout_path app.server_log
pid app.pidfile
listen "unix:#{app.socket}", :backlog => 64
#user 'user', 'group'
worker_processes app.instances
timeout 30
preload_app true

# Use COW-friendly REE for memory saving, especially with preloaded apps
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

before_fork do |server, worker|
  # For preloaded apps, it is highly recommended to disconnect any database
  # connection and reconnect it in the worker
  if server.config[:preload_app]
    ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
  end

  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # # This allows a new master process to incrementally
  # # phase out the old master process with SIGTTOU to avoid a
  # # thundering herd (especially in the "preload_app false" case)
  # # when doing a transparent upgrade.  The last worker spawned
  # # will then kill off the old master process with a SIGQUIT.
  # old_pid = "#{server.config[:pid]}.oldbin"
  # if old_pid != server.pid
  #   begin
  #     sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
  #     Process.kill(sig, File.read(old_pid).to_i)
  #   rescue Errno::ENOENT, Errno::ESRCH
  #   end
  # end
  #
  # # *optionally* throttle the master from forking too quickly by sleeping
  # sleep 1
end

after_fork do |server, worker|
  # Per-process listener ports for debugging/admin/migrations
  #addr = "127.0.0.1:#{9293 + worker.nr}"
  #server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)

  # Reconnect the database connection in the worker (see disconnect above)
  if server.config[:preload_app]
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
    # TODO: check for other database mapper and reconnect them (mongo, memcache, redis)
  end
end