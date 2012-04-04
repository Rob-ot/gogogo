###
CLI to automatically deploy stuff, kind of like heroku. 
Ubuntu only! (upstart)
###

APP = "gogogo"
PREFIX = "ggg"

{spawn, exec} = require 'child_process'
fs = require 'fs'
path = require 'path'

args = process.argv.slice(2)
action = args[0]
name = args[1]
server = args[2]

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
    id = PREFIX + "_" + path.basename(url).replace(".git","") + "_" + name
    parent = "$HOME/" + PREFIX
    wd = "#{parent}/#{id}"
    repo = wd + ".git"
    upstart = "/etc/init/#{id}.conf"
    logfile = "log.txt"
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
      exec npm start >> #{logfile} 2>&1
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
      mkdir -p #{wd}
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

# RUN THE THING

done = (err) ->
  if err?
    console.log err.message
    process.exit 1
  console.log "OK"

usage = -> console.log "Usage: gogogo create NAME USER@SERVER"

switch action
  when "add" then create name, server, done
  else usage()
