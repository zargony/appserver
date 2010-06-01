Automagic application server configurator
=========================================

Monit/Nginx/Unicorn application server configurator using deployment via git
(simply git push applications to your server to deploy them).

This tool automatically generates server configs for [Monit][monit],
[Nginx][nginx] and [Unicorn][unicorn] to host your [Rack][rack]-based (Rails)
applications. Running it automatically in git update hooks provides an
automatic deployment of applications whenever the repository is updated
on the server.

Requirements
------------

A server running [Monit][monit], [Nginx][nginx] and having [Git][git] and
Ruby with RubyGems installed.

Install
-------

    gem install appserver

Or check out the [repository][repo] on github.

Setup
-----

### Initialize an appserver directory

To run applications, you need to initialize an appserver directory first. To
do so, run `appserver init`.

    $ appserver init /var/webapps

An appserver directory holds configuration files and everything needed to run
multiple applications (application code, temp files, log files, ...). You can
customize settings by editing the `appserver.conf.rb` configuration file. **All
other files are updated automatically and should not be modified manually.**

### Activate generated Nginx configuration

Modify your system's Nginx configuration (e.g. `/etc/nginx/nginx.conf` on
Ubuntu) to include the generated `nginx.conf` **inside a `http` statement**.
Reload Nginx to apply the configuration changes.

*/etc/nginx/nginx.conf:*

    ⋮
    http {
      ⋮
      include /var/webapps/nginx.conf;
    }
    ⋮

### Activate generated Monit configuration

Modify your system's Monit configuration (e.g. `/etc/monit/monitrc` on Ubuntu)
to include the generated `monitrc` at the bottom. Reload Monit to apply the
configuration changes.

*/etc/monit/monitrc:*

    ⋮
    include /var/webapps/monitrc

### Optional: Activate generated Logrotate configuration

Modify your system's Logrotate configuration (e.g. `/etc/logrotate.conf` on
Ubuntu) to include the generated `logrotate.conf` at the bottom. Logrotate
is typically executed from cron, so there's no daemon to reload to apply the
configuration changes.

*/etc/logrotate.conf:*

    ⋮
    include /var/webapps/logrotate.conf

Deploying an application
------------------------

Deploying an application is easy: simply run `appserver deploy /path/to/repository.git`
to deploy the application and run `appserver update` to update generated
configuration files.

    $ cd /var/webapps
    $ appserver deploy /var/git/myblog.git
    $ appserver update

After that, the application will be automatically deployed every time you
push changes to the repository.

How it works
------------

In general: every appserver command (except `init`) needs to be run from an
initialized appserver directory (or you need to specify the appserver directory
using the -d option). Also, appserver commands do never modify anything outside
their current appserver directory.

The `deploy` command does two things:

1. It checks out the repository (master branch by default) and installs it to
   the appserver directory (which also involves symlinking temp directories,
   creating a gem bundle, and so on).
2. It installs an update hook script to the repository, that runs the deploy
   command everytime you push to the repository from now on.

After deploy, there's a ready-to-run copy of the application in the appserver
directory, that just needs to be started.

The `update` command updates generated configuration files for Monit and Nginx.
If you properly included the generated configuration files to your system
configuration, Monit will automatically detect updated configuration files and
reload the corresponding system processes (even itself).

For every deployed application, Monit is configured to start a Unicorn server
process with the configured number of instances (Unicorn workers) and keep it
running. Whenever a different revision of the application is deployed, it
gracefully restarts the server process (using Unicorn's SIGUSR2/SIGQUIT
mechanism) without interrupting requests. Nginx is configured to forward
incoming HTTP requests to the Unix socket of the Unicorn process for the
corresponding Rack application. Static files are served directly by Nginx for
performance.

Btw, Monit only runs periodically (typically 60 second cycles), so you might
have to wait a few seconds until changes are recognized and processes are
reloaded.

Security considerations
-----------------------

to be done...

Author
------

Andreas Neuhaus :: <http://zargony.com/>

[repo]: http://github.com/zargony/appserver/
[monit]: http://mmonit.com/monit/
[nginx]: http://nginx.com/
[unicorn]: http://unicorn.bogomips.org/
[git]: http://git-scm.com/
[rack]: http://rack.rubyforge.org/
