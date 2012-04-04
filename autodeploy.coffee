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

{spawn, exec} = require 'child_process'
fs = require 'fs'
path = require 'path'

APP = "woot"
CONF = "woot.json"
DEFAULT = "default"

args = process.argv.slice(2)
server = args[0]
name = args[1]
repo = args[2]

server = "root@dev.i.tv"
name = "test-autodeploy"


# gets the repo url for the current directory
repourl = (dir, cb) ->
  exec "git config --get remote.origin.url", {cwd:dir}, (err, stdout, stderr) ->
    if err? then return cb(new Error("Could not find git url"))
    cb null, stdout.replace("\n","")

# reads a config file
read = (f, cb) ->
  fs.readFile f, (err, data) ->
    if err? then return cb(new Error("Missing: " + f))

    try
      parsed = JSON.parse(data)
    catch e
      return cb(new Error("JSON Error: " + e.message))

    cb null, parsed

# sets everything up so git pushes work in the future!
create = (server, name, cb) ->
  console.log "CREATING"
  console.log " name: #{name}"
  console.log " server: #{server}"
  repourl process.cwd(), (err, url) ->
    if err? then return cb err
    console.log " repo: #{url}"

    # DON'T NEED CONF FILE YET
    #read confFile, (err, c) ->
      #if err? then return cb err
      #if not run? then return cb(new Error(CONF + " should specify run:"))

    # unique service name
    uniqueName = APP + "_" + path.basename(url).replace(".git","") + "_" + name
    repoPath = "~/woot/" + uniqueName
    upstartPath = "/etc/init/#{uniqueName}.conf"
    logPath = "#{repoPath}/log.txt"

    console.log " id: #{uniqueName}"
    console.log " path: #{repoPath}"

    # upstart service
    service = """
      description '#{uniqueName}'
      start on startup
      chdir #{repoPath}
      respawn
      respawn limit 5 5 
      exec bash woot.sh >> #{logPath}
    """

    # command
    commands = """
      cd ~
      mkdir -p #{repoPath}
      git clone #{url} #{repoPath}
      echo "#{service}" > #{upstartPath}
    """

    #console.log "---------------------"
    #console.log commands
    console.log "---------------------"

    ssh = spawn 'ssh', [server, commands]
    ssh.stdout.on 'data', (data) -> console.log data.toString()
    ssh.stderr.on 'data', (data) -> console.log data.toString()
    ssh.on 'exit', (code) -> 
      if code then cb(new Error("Failed"))
      cb()

deploy = (name, cb) ->
  console.log "DEPLOYING"
  console.log " name: #{name}"

#create "root@dev.i.tv", "test", (err) ->
  #if err?
    #console.log err.message
    #process.exit 1
  #console.log "OK"
