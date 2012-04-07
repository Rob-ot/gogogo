###
CLI to automatically deploy stuff, kind of like heroku. 
Ubuntu only! (upstart)

NEXT STEPS
Real use case: an individual deploy location is associated with a branch, most of the time. (but not all)

gogogo create dev root@dev.i.tv
 - stores a .ggg/dev.js config file
 - format: module.exports = {} 
 - you commit this (can edit by hand?) 
 - if the file exists then return early
 - does NOT add the git remote (deploy does)

gogogo dev master
 - needs to work even if you haven't added the git remote!
 - deploys master to dev
 - sets .ggg/_.js -> branch=master, 

gogogo
 - runs last "gogogo" command, whatever that was
 - stores to .ggg/_.js

gogogo list
 - shows you the names

http://stackoverflow.com/questions/7152607/git-force-push-current-working-directory
-- git config receieve.denyCurrentBranch ignore
-- and git checkout -f 
will do it!

###

APP = "gogogo"
PREFIX = "ggg"
CONFIG = ".ggg"

{spawn, exec} = require 'child_process'
fs = require 'fs'
path = require 'path'








# gets the repo url for the current directory
# if it doesn't exist, use the directory name
reponame = (dir, cb) ->
  exec "git config --get remote.origin.url", {cwd:dir}, (err, stdout, stderr) ->
    if err?
      cb null, path.basename(path.dirname(dir))
    else
      url = stdout.replace("\n","")
      cb null, path.basename(url).replace(".git","")

# write a config file
writeConfig = (f, obj, cb) ->
  fs.mkdir path.dirname(f), (err) ->
    fs.writeFile f, "module.exports = " + JSON.stringify(obj), 0775, cb

# read a config file
readConfig = (f, cb) ->
  cb null, require f

namedConfig = (name) -> path.join process.cwd(), CONFIG, name+".js"
mainConfig = -> path.join process.cwd(), CONFIG, "_main.js"

readNamedConfig = (name, cb) ->
  readConfig namedConfig(name), cb

serviceId = (repoName, name) -> repoName + "_" + name

# add a git remote
# NOT IN USE (you can push directly to a git url)
addGitRemote = (name, url, cb) ->
  exec "git remote rm #{name}", (err, stdout, stderr) ->
    # ignore errs here, the remote might not exist
    exec "git remote add #{name} #{url}", (err, stdout, stderr) ->
      if err? then return cb err
      cb()

ssh = (server, commands, cb) ->
  local 'ssh', [server, commands], (err) ->
    if err? then return cb new Error "SSH Command Failed"
    cb()


# runs the commands and dumps output as we get it
local = (command, args, cb) ->
  process = spawn command, args
  process.stdout.on 'data', (data) -> console.log data.toString()
  process.stderr.on 'data', (data) -> console.log data.toString()
  process.on 'exit', (code) ->
    if code then return cb(new Error("Command Failed"))
    cb()


# git pushes or no? NO
# sets everything up so git pushes work in the future!
create = (name, server, cb) ->
  console.log "GOGOGO CREATING!"
  console.log " name: #{name}"
  console.log " server: #{server}"

  reponame process.cwd(), (err, rn) ->
    if err? then return cb err

    # names and paths
    id = serviceId rn, name
    parent = "$HOME/" + PREFIX
    repo = wd = "#{parent}/#{id}"
    upstart = "/etc/init/#{id}.conf"
    log = "log.txt"
    hookfile = "#{repo}/.git/hooks/post-receive"
    deployurl = "ssh://#{server}/~/#{PREFIX}/#{id}"

    console.log " id: #{id}"
    console.log " repo: #{repo}"
    console.log " remote: #{deployurl}"

    # upstart service
    service = """
      description '#{id}'
      start on startup
      chdir #{repo}
      respawn
      respawn limit 5 5 
      exec npm start >> #{log} 2>&1
    """

    # http://toroid.org/ams/git-website-howto
    # don't use a hook any more, except to check out
    hook = """
      read oldrev newrev refname
      echo 'GOGOGO HOOK!'
      echo \\$newrev
      cd #{repo}/.git
      GIT_WORK_TREE=#{repo} git reset --hard \\$newrev || exit 1;
    """

    # command
    remote = """
      mkdir -p #{repo}
      cd #{repo}
      git init
      git config receive.denyCurrentBranch ignore

      echo "#{service}" > #{upstart}

      echo "#{hook}" > #{hookfile}
      chmod +x #{hookfile}
    """

    ssh server, remote, (err) ->
      if err? then return cb err

      # write config
      config = {name: name, server: server, id: id, repoUrl: deployurl, repo: repo}

      writeConfig namedConfig(name), config, (err) ->
        if err? then return cb new Error "Could not write config file"

        console.log "-------------------------------"
        console.log "deploy: 'gogogo #{name} BRANCH'"

        cb()

# we add the git remote at this point, not when we create, because we want anyone who checks out the code to also be able to deploy. I could also temporarily add a git remote? Can you push directly to a url? 
deploy = (name, branch, cb) ->
  readNamedConfig name, (err, config) ->
    if err? then return cb err
    console.log("PUSHING")
    local "git", ["push", config.repoUrl, branch], (err) ->
      if err? then return cb err

      command = """
        echo 'INSTALLING'
        cd #{config.repo}
        npm install --unsafe-perm || exit 1;
        echo 'RESTARTING'
        stop #{config.id}
        start #{config.id}
      """

      ssh config.server, command, cb

# starts, or restarts the service
restart = (name, cb) ->
  readNamedConfig name, (err, config) ->
    if err? then return cb err
    ssh config.server, "stop #{config.id}; start #{config.id}", cb

stop = (name, cb) ->
  readNamedConfig name, (err, config) ->
    if err? then return cb err
    ssh config.server, "stop #{config.id};", cb

start = (name, cb) ->
  readNamedConfig name, (err, config) ->
    if err? then return cb err
    ssh config.server, "start #{config.id};", cb

# this should never exit. You have to Command-C it
logs = (name, cb) ->
  readNamedConfig name, (err, config) ->
    if err? then return cb err
    log = config.repo + "/log.txt"
    console.log "Tailing #{log}... Control-C to exit"
    console.log "-------------------------------------------------------------"
    ssh config.server, "tail -f #{log}", cb

done = (err) ->
  if err?
    console.log err.message
    process.exit 1
  console.log "OK"

usage = -> console.log "Usage: gogogo create NAME USER@SERVER"




# RUN THE THING
args = process.argv.slice(2)
action = args[0]

switch action
  when "add" then create args[1], args[2], done
  when "restart" then restart args[1], done
  when "start" then start args[1], done
  when "stop" then stop args[1], done
  when "logs" then logs args[1], done
  when "deploy" then deploy args[1], args[2], done
  else usage()
