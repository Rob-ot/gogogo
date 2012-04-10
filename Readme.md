Go Go Go
========

Gogogo is a simple command-line tool designed to let you deploy web applications as easily as possible. It looks for a package.json file to get information about how to run and install your application.

While this uses package.json, it isn't specific to node. You can specify anything in `install` and `start`. These are generic package.json fields supported by npm. 

### Goals

1. Easy to setup
2. Easy to redeploy 
3. Deploy to multiple servers
4. Deploy different branches to the same server

Installation
------------

    npm -g install gogogo

Server Requirements
-------------------

1. Upstart (included with ubuntu)
2. SSH Access

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

    gogogo create <name> <server>
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

in your local terminal

    # you only need to run this once
    gogogo create test someuser@example.com

    # now deploy over and over
    gogogo deploy test master

    # change some stuff
    ...

    # deploy again
    gogogo deploy test master
    
    # it remembers your last name and branch
    gogogo deploy

Limitations
-----------

1. Only works on ubuntu (requires upstart to be installed)
2. Can't handle scheduled tasks yet (cron)
3. Can't handle server-level environment variables yet

Roadmap
-------

* cron
* gogogo rm
* gogogo ps
* ability to specify sub-folders that contain package.json files

Help
----

### Actions

    gogogo help

    gogogo create <name> <server> 
    gogogo deploy [<name>] [<branch>]

    gogogo restart [<name>]
    gogogo start [<name>]
    gogogo stop [<name>]

    gogogo logs [<name>]

    gogogo list 

### Environment variables

If they are the same no matter which server is deployed, put them in your start script. 

    "start":"DB_HOST=localhost node app.js"

If they refer to something about the server you are on, I'd like to figure out a way to set them on the server itself, so that any app on that server has the variables. I don't know how to do this yet.  

### Multiple servers

To deploy to multiple servers, just run `gogogo create` with the different servers and pick a unique `name` each time.

    gogogo create test user@test.example.com
    gogogo create staging user@staging.example.com

    gogogo deploy test master
    gogogo deploy staging master

### Multiple branches on the same server

You can deploy any branch over your old remote by pushing to it. To have multiple versions of an app running at the same time, call `gogogo create` with different names and the same server.

    gogogo create test user@test.example.com
    gogogo create featurex user@test.example.com
    
    gogogo deploy test master
    gogogo deploy featurex featurex

Note that for web servers you'll want to change the port in your featurex branch or it will conflict.

### Remembers Last Name and Branch

You can leave the name and branch off any command and it will use the last name and branch from `gogogo deploy`

    gogogo deploy
    gogogo restart
    gogogo logs


