# This is an appserver directory configuration of the "appserver" gem. Use the
# "appserver" command or visit http://github.com/zargony/appserver for details

#
# SERVER SETTINGS
# Non application specific. Paths are relative to the appserver directory. The
# appserver directory is the directory, that contains this configuration file.
#

# Path/name of the Monit configuration snippet that should be written
#monit_conf 'monitrc'

# Command to execute to tell Monit to reload the configuration. Used within
# the Monit snippet, so this command will be called as root
#monit_reload '/usr/sbin/monit reload'

# Path/name of the Nginx configuration snippet that should be written
#nginx_conf 'nginx.conf'

# Command to execute to tell Nginx to reload the configuration. Used within
# the Monit snippet, so this command will be called as root
#nginx_reload '/usr/sbin/nginx -s reload'

# Command to execute to tell Nginx to reopen the log files. Used within
# the Logrotate snippet, so this command will be called as root
#nginx_reopen '/usr/sbin/nginx -s reopen'

# Path/name of the logrotate configuration snippet that should be written
#logrotate_conf 'logrotate.conf'


#
# APPLICATION SETTINGS
# Can be either specified globally for all applications or application-
# specific in an "app" block (see examples at the bottom of this file).
# Paths are relative to the respective directory of the application
#

# Branch to check out when deploying an application. Defaults to 'master'
#branch 'master'

# Name/path of the command to call Ruby. By default, this points to the
# ruby command in your PATH, usually /usr/bin/ruby. Set this, if you want
# to use a manually installed ruby that is not in your PATH. If you're using
# RVM, you can use "/usr/local/bin/rvm XYZ ruby" here to easily use
# different Ruby versions for different applications. Make sure the
# targetted Ruby version also has the appserver gem installed!
#ruby '/usr/bin/ruby'

# Rack environment to run the application in. Defaults to 'production'
#environment 'production'

# User and group to run the instance server under. If user is left empty, the
# user who owns the application directory is used. If group is left empty, the
# primary group of the user is used. For security reasons, you might want to
# set this to a different user than the file owner. (Debian based systems
# typically use "www-data"). Using root here would be a real bad idea
#user 'www-data'
#group 'www-data'

# Number of instances (unicorn workers) for an application. This defaults to
# the number of CPUs detected, which should be fine for most cases (read the
# unicorn tuning tips before changing this)
#instances 2

# Use Unicorn's application preloading before forking instances. Defaults to
# false (preloading disabled)
#preload false

# By default, only PATH, PWD, GEM_HOME and GEM_PATH environment settings are
# preserved. If you need more environment variables to be preserved, add them
# here. If you set this to '*', all environment variables are preserved
#env_whitelist [ 'SOME_VAR', 'SOME_OTHER_VAR' ]

# In addition to the whitelisted environment variables, RACK_ENV and
# BUNDLE_PATH are set. If want to set more environment variables, specify
# them here
#env { 'KEY' => 'value' }

# Let Monit watch the CPU usage of instances and restart them if their
# CPU usage exceeds this value
#max_cpu_usage '80%'

# Let Monit watch the memory usage of instances and restart them if their
# memory usage exceeds this value
#max_memory_usage '100Mb'

# When doing CPU/memory usage checks, only restart an instance if it exceeds
# a resource for at least this number of Monit cycles
#usage_check_cycles 5

# Let Monit check periodically, if instances provide an answer to HTTP
# requests within the given timeout, or restart them if they don't. Set
# to 0 to disable
#http_check_timeout 30

# The domain will be used as the base domain for applications which you
# don't specifically set a hostname for. For these applications, a
# hostname of "<appname>.<domain>" will be set automatically. The hostname
# tells Nginx, which requests to route to the application and therefore
# makes it possible to run multiple domains on a single IP address. The
# domain setting defaults to the system's domainname
#domain 'example.com'

# If a SSL certificate and key are set, Nginx will be configured to accept
# HTTPS connections as well. The default is to only accept HTTP
#ssl_cert '/etc/ssl/certs/mydomain.pem'
#ssl_key '/etc/ssl/private/mydomain.key'

# Path where public static files should be served from by Nginx. Defaults to
# the public directory in the application
#public_dir 'public'


#
# APPLICATIONS
# All application default settings from above can be overridden for specific
# applications. You most probably want to set "hostname" to your liking here.
# Most other settings should do well with their defaults in most cases.
#

# A simple blog application named "myblog"
#app 'myblog' do
#  hostname 'blog.example.com'
#  instances 1
#end
