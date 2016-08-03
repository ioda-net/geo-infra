# geo-infra

This repository contains all scripts and template used to manage geo-front3 and geo-api3. It relies on a collection of Bash and Python3 scripts. Tasks are launched with [manuel](https://github.com/ShaneKilkelly/manuel) a task runner for Bash. You will also need [nodejs](https://nodejs.org) to build the frontend.



## Getting ready

1. git clone git@github.com:ioda-net/geo-infra.git
2. Install the python dependencies with `pip install -r requires.txt`. If you use a version of Python below 3.4, you'll need glob2. You can install it this way: `pip install glob2`.
3. Clone the relevant infra directory where you want. For instance, clone [ioda-infra](https://github.com/ioda-net/ioda-infra) in the same folder than geo-infra: `git clone git@github.com:ioda-net/ioda-infra.git`.
4. Clone [geo-front3](https://github.com/ioda-net/geo-front3): `git clone git@github.com:ioda-net/geo-front3.git`.
5. Clone [geo-api3](https://github.com/ioda-net/geo-api3): `git clone git@github.com:ioda-net/geo-api3.git`.


### Setup API

1. Create the proper venv with `./manuel venv`. For this to run, you may need to install the following packages: geos, geos-devel, postgresql-devel, libxml2-devel, libxslt-devel
2. Prepare the configuration
   1. `config/config.dist.sh` contains variables used in shell scripts (PYTHONPATH and path to various commands). You can create `config/config.sh` to override any value you may need.
   2. `config/config.dist.toml` contains variables used to generate `production.ini` and `developement.ini`. These files are then used by the API as its configuration. You can create a `config/config.<branch-name>.toml` to override any variable you may need for the branch you are on.

You are now ready to lanch the API with `manuel serve`.


### Setup the frontend

1. Install the nodejs dependencies with `npm install`.


### Setup geo-infra

1. Setup the configuration:
   1. Create a symlink in `cgi-bin` to you mapserver executable. It will be used to get the list of available layers from the generated map files.
   2. `config/config.dist.sh` contains variable used by shell scripts. You can override any value by creating a `config/config.sh` file. To override a value, use the `set-var` function. It will only set the variable if it is not defined in your environment.
   3. The toml files will contain variables used to generate the configuration of a portal. You probably want to create a `config/dev/_common.dev.toml` to override the `search.conf_dir`. It must point to the folder that will contains the generated search locations. For development, the root of the geo-infra repo is a good value. See the note below to learn more about how the configuration system works.


The configuration system works as follow: the `global.toml` file is loaded, then `dist/_common.dist.toml`, then `prod/_common.prod.toml` (if present) and if you are using a task for development `dev/_common.dev.toml` is loaded (if present). Then the configuration from the portal infrastructure directory will be loaded following the same pattern. The configuration file named after the portal will be loaded last.


### Setup your portal infrastructure (here: ioda-infra)

Check the value in the config files and override them if necessary.


### Setup you vhost

#### API

Here is a sample vhost file for the API:

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName api.geoportal-demo.local

    RewriteEngine on
    ExpiresActive on

    # Remove timestamp from URL
    RedirectMatch ^/[0-9]+/(.*)$ /$1
    RewriteCond "%{REQUEST_URI}" ^/[0-9]+
    RewriteRule ^/[0-9]+/(.*)$ /$1 [PT]

    # Enabling CORS
    Header setifempty Access-Control-Allow-Origin "*"
    Header setifempty Access-Control-Allow-Methods "POST, GET, OPTIONS"
    Header setifempty Access-Control-Allow-Headers "X-Requested-With, content-type"

    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/x-javascript application/javascript application/json application/xml
    AddOutputFilterByType DEFLATE text/html text/plain text/xml

    ProxyPass / http://localhost:9000/ connectiontimeout=5 timeout=30
</VirtualHost>
```

#### Front

Here is a sample vhost for the front end:

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName geoportal-demo.local
    ServerAlias localhost

    LogLevel debug

    DocumentRoot /home/jenselme/Work/geoportal-infras/ioda-infra/dev/geoportalxyz
    <Directory  /home/jenselme/Work/geoportal-infras/ioda-infra/dev/geoportalxyz>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    RewriteEngine On
    ExpiresActive On

    # Enabling CORS
    Header always set Access-Control-Allow-Origin "*"
    Header always set Access-Control-Allow-Methods "POST, GET, OPTIONS"
    Header always set Access-Control-Allow-Headers "X-Requested-With, content-type"
    Header set X-UA-Compatible "IE=Edge"

    FileETag none

    AddType application/json .json
    AddType application/font-woff .woff
    AddType text/cache-manifest .appcache

    ExpiresByType text/cache-manifest "access plus 0 seconds"
    ExpiresByType text/html "access plus 0 seconds"

    # Redirect no-slash target to slashed version
    RedirectMatch ^$ /

    SetEnvIf Request_URI "/ows/osm" MS_MAPFILE=/home/jenselme/Work/geoportal-infras/ioda-infra/dev/geoportalxyz/map/portals/geoportalxyz.map
    ScriptAlias /ows /home/jenselme/Work/mapserver/wms	
    <Directory  /home/jenselme/Work/mapserver/wms>
	AllowOverride None
	Options +ExecCGI -MultiViews +FollowSymlinks
	Require all granted
    </Directory>

    <LocationMatch ^/print.*>
	Header set Cache-Control "no-cache"
    </LocationMatch>

    # Checker definitions (never cache)
    <Location ~ "/checker$">
	ExpiresDefault "access"
	Header merge Cache-Control "no-cache"
	Header unset ETag
	Header unset Last-Modified
    </Location>

    ProxyPass /print http://localhost:8080/print/print/ connectiontimeout=5 timeout=30
    ProxyPassReverse /print http://localhost:8080/print/print/
</VirtualHost>
```


## Set-up sphinx

Search relies on [sphinxsearch](http://sphinxsearch.com/). You can install it on most linux distribution with the sphinx package. Make `/etc/sphinx/sphinx.conf` a symlink to the generated `sphinx.conf` (for developement: `/path/to/geo-infra/dev/search/sphinx.conf`.


## Create a portal for dev

You should be ready to create a portal with `./manuel dev-full geoportalxyz`. If you go at `geoportal-demo.local` you should see you newly created portal.


## Alias System

If two portals or more in different infra directories have the same name, you can create an alias for this portal.

To do so, create a file `geo-infra/.aliases`. Put each alias on a line following this convention: `alias name-infra name`. For instance `demo ioda-infra geoportalxyz`.

You can then run any command with the alias. For instance: `manuel dev-full demo`. The files will be generated in the proper infra directory under the name of the portal. Search indexes and print configuration will be named after the alias. The `portalAlias` key in `gaGlobalConf` will be set to the alias name. This name will be used to the API when doing search and print.

Don't put any dash in the alias name and if possible only use letters and numbers. Any other character may prevent search to function properly in the API.
