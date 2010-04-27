Automagic application server configurator
=========================================

Monit/Nginx/Unicorn application server configurator using deployment via git
(simply git push applications to your server to deploy them).

This little tool automatically generates server configs for [Monit][monit],
[Nginx][nginx] and [Unicorn][unicorn] to host your [Rack][rack]-based (Rails)
applications. Running it automatically in git post-receive hooks provides
an automatic deployment of applications whenever the repository is updated
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

To run applications, you need to initialize a server directory first. To do
so, create an empty directory and run `appserver init` in it. 

    $ mkdir /var/webapps
    $ cd /var/webapps
    $ appserver init

A server directory holds configuration files and applications in
subdirectories. You can customize things by editing the `appserver.yml`
configuration. **Any other file/directory is updated automatically and should
not be modified manually.**

Modify your system's Monit configuration (e.g. `/etc/monit/monitrc` on Ubuntu)
to include the generated `monitrc` at the bottom and reload Monit.

*/etc/monit/monitrc:*

    ⋮
    include /var/webapps/monitrc

Modify your system's Nginx configuration (e.g. `/etc/nginx/nginx.conf` on
Ubuntu) to include the generated `nginx.conf` **inside a `http` statement**
and reload Nginx.

*/etc/nginx/nginx.conf:*

    ⋮
    http {
      ⋮
      include /var/www/nginx.conf;
    }
    ⋮

Deploying an application
------------------------

to be done...

How it works
------------

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
