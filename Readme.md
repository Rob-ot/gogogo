Go Go Go
========

Gogogo is a cli designed to let you deploy via git hooks to your own server, heroku-style. It uses your package.json file to get information about how to run and install your application

Installation
------------

    npm -g install gogogo

Usage
-----

    gogogo add <name> <server>
    git push <name> <branch>


Example
-------
    
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


