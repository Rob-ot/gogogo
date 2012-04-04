###
CLI to automatically deploy stuff, kind of like heroku. 
Ubuntu only! (upstart)

woot.sh (what you need to run your file - same for each server)

woot create <SERVER> <NAME>
 - creates a new deploy of your app, remembers the name

woot <NAME> <BRANCH>
 - deploys the branch to the named location

RUN - node app.js (restart/start)
INSTALL - npm install (deploy)

NAMES
 - remember the server
 - set environment variables
 - remember the last branch?

woot run
 - runs from woot.json

DEFAULTS: 
woot create <SERVER> (default)
woot deploy <BRANCH> (default)
woot deploy (default) (master)
woot run


WORK WITH TVSERVER? - you can specify super.conf in the command-line arguments

###

APP = "gogogo"

{spawn, exec} = require 'child_process'
fs = require 'fs'
path = require 'path'

args = process.argv.slice(2)
server = args[0]
name = args[1]
repo = args[2]

server = "root@dev.i.tv"
name = "test-autodeploy"


# 1 # create: sets up the git repo, creates a git remote for you?
# 2 # deploy: automatic on git hook

# gets the repo url for the current directory
repourl = (dir, cb) ->
  exec "git config --get remote.origin.url", {cwd:dir}, (err, stdout, stderr) ->
    if err? then return cb(new Error("Could not find git url"))
    cb null, stdout.replace("\n","")

# sets everything up so git pushes work in the future!
create = (server, name, cb) ->
  console.log "CREATING"
  console.log " name: #{name}"
  console.log " server: #{server}"
  repourl process.cwd(), (err, url) ->
    if err? then return cb err
    console.log " repo: #{url}"

    # names and paths
    id = APP + "_" + path.basename(url).replace(".git","") + "_" + name
    parent = "~/" + APP
    wd = "#{parent}/#{id}"
    repo = wd + ".git"
    upstart = "/etc/init/#{id}.conf"
    log = "#{wd}/log.txt"
    hookfile = "#{repo}/hooks/post-receive"
    deployurl = "ssh://#{server}/#{repo}"

    console.log " id: #{id}"
    console.log " repo: #{repo}"
    console.log " wd: #{wd}"
    console.log " remote: #{deployurl}"

    # upstart service
    service = """
      description '#{id}'
      start on startup
      chdir #{wd}
      respawn
      respawn limit 5 5 
      exec npm start >> #{log}
    """

    # http://toroid.org/ams/git-website-howto
    # git clone --bare URL <name>.git
    # git post-receive hook
    hook = """
      #!/bin/sh
      GIT_WORK_TREE=#{wd} git checkout -f
      cd #{wd}
      npm install
      start #{id}
    """

    # command
    remote = """
      mkdir -p #{parent}
      git clone --bare #{url} #{repo}
      echo "#{service}" > #{upstart}
      echo "#{hook}" > #{hookfile}
      chmod +x #{hookfile}
    """

    console.log "---------------------"
    console.log remote
    console.log "---------------------"

    ssh = spawn 'ssh', [server, remote]
    ssh.stdout.on 'data', (data) -> console.log data.toString()
    ssh.stderr.on 'data', (data) -> console.log data.toString()
    ssh.on 'exit', (code) -> 
      if code then cb(new Error("Failed"))

      # now install local stuff
      exec "git remote rm #{name}", (err, stdout, stderr) ->
        # ignore errs here, the remote might not exist
        exec "git remote add #{name} #{deployurl}", (err, stdout, stderr) ->
          if err? then return cb err
          cb()



create "root@dev.i.tv", "test", (err) ->
  if err?
    console.log err.message
    process.exit 1
  console.log "OK"
