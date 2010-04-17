Automagic Server Configuration for Webapps
==========================================

Simply git push applications to your server to deploy them.

This little tool automatically generates server configs for [Monit][monit]
and [Nginx][nginx] to host your [Rack][rack]-based (Rails) applications.
Running it in git post-receive hooks on your server will give you an
automatic deployment of your applications whenever you git push them to
the server.

Requirements
------------

* [Monit][monit]
* [Nginx][nginx]
* [Git][git]
* Ruby with Gems, Rake, Thin

Setup
-----

1. Put the `Rakefile` into an empty directory or check out the [repository][repo].
   This directory will serve as a the base directory for the web applications.
2. Change to the newly created directory and run `rake`.
3. Modify the system's monit configuration to include the generated `monitrc`
   and reload monit.
4. Modify the system's nginx configuration to include the generated `nginx.conf`
   and reload nginx.

### Example install (Ubuntu)
    git clone git://github.com/zargony/appserver-config.git /opt/webapps
    cd /opt/webapps
    rake
    echo "include /opt/webapps/monitrc" >>/etc/monit/monitrc
    monit reload
    echo "include /opt/webapps/nginx.conf" >>/etc/nginx/nginx.conf
    service nginx reload

Author
------

Andreas Neuhaus :: <http://zargony.com/>

[repo]: http://github.com/zargony/appserver-config/
[monit]: http://mmonit.com/monit/
[nginx]: http://nginx.com/
[git]: http://git-scm.com/
[rack]: http://rack.rubyforge.org/
