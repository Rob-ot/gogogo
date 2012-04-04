Go Go Go
========

Gogogo is a cli designed to let you deploy via git hooks to your own server, heroku-style. It uses your package.json file to get information about how to run and install your application

Installation
------------

    npm -g install gogogo

Usage
-----

### package.json

    { 
        "name":"somemodule",
        ...
        "scripts": {
          "install":"anything you want to do before starting, like compiling coffee scripts",
          "start":"command to start your server"
        }
    }

### in your local repo

    gogogo add <name> <server>
    git push <name> <branch>


### example
    
    gogogo add test someuser@example.com
    git push test master

Limitations
-----------

1. Only works on ubuntu (requires upstart to be installed)
2. Can't handle cron yet

Roadmap
-------

* cron
* gogogo rm
* gogogo ps
* gogogo logs
* gogogo restart
* ability to specify sub-folders that contain package.json files


