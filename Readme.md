Go Go Go
========

Gogogo is a cli designed to let you deploy via git hooks to your own server, heroku-style. It uses your package.json file to get information about how to run and install your application.

While this uses package.json, it isn't specific to node. You can specify anything in `install` and `start`

### Goals

1. Easy to setup
2. Easy to redeploy 
3. Deploy to multiple servers
4. Deploy different branches to the same server

Installation
------------

    npm -g install gogogo

Usage
-----

### package.json

Note: these are standard package.json scripts, and can be tested locally with `npm install` and `npm start`

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

package.json

    { 
        "name":"somemodule",
        ...
        "scripts": {
          "install":"coffee -c .",
          "start":"PORT=5333 node app.js"
        }
    }


bash

    # you only need to run this once
    gogogo add test someuser@example.com

    # now deploy over and over
    git push test master

    # change some stuff
    ...

    # deploy again
    git push test master

Limitations
-----------

1. Only works on ubuntu (requires upstart to be installed)
2. Can't handle cron yet
3. Server-level environment variables

Roadmap
-------

* cron
* gogogo rm
* gogogo ps
* ability to specify sub-folders that contain package.json files

    √ gogogo logs
    √ gogogo restart

Help
---

### Environment variables

If they are the same no matter which server is deployed, put them in your start script. 

    "start":"DB_HOST=localhost node app.js"

If they refer to something about the server you are on, I'd like to figure out a way to set them on the server itself, so that any app on that server has the variables. I don't know how to do this yet.  

### Multiple servers

To deploy to multiple servers, just run `gogogo add` with the different servers and pick a unique `name` each time.

    gogogo add test user@test.example.com
    gogogo add staging user@staging.example.com

    git push test master
    git push staging master

### Multiple branches on the same server

You can deploy any branch over your old remote by pushing to it. To have multiple versions of an app running at the same time, call `gogogo add` with different names and the same server.

    gogogo add test user@test.example.com
    gogogo add featurex user@test.example.com
    
    git push test master
    git push featurex featurex

Note that for web servers you'll want to change the port in your featurex branch or it will conflict.


    


