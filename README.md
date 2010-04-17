Config generator for git/monit/nginx
====================================

This little tool automatically generates server configs for git, monit
and nginx that provide easy and automatic web application deployment
via git push.

Requirements
------------

* [Monit](http://mmonit.com/monit/)
* [Nginx](http://nginx.com/)
* [Git](http://git-scm.com/)
* Ruby, RubyGems, Rake, Thin

Setup
-----

1. Put the `Rakefile` into an empty directory or check out the repository. This
   directory will serve as a the base directory for the web applications.
2. Change to the newly created directory and run `rake`.
3. Modify the system's monit configuration to include the generated `monitrc`
   and reload monit.
4. Modify the system's nginx configuration to include the generated `nginx.conf`
   and reload nginx.

Author
------

Andreas Neuhaus :: <http://zargony.com/>
