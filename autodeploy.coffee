# command-line program to automatically deploy stuff
# our arguments

# step one: create a new app on the server
# step two: git push it

cp = require 'child_process'
spawn = cp.spawn
exec = cp.exec

args = process.argv.slice(2)
server = args[0]
name = args[1]
repo = args[2]

server = "root@dev.i.tv"
name = "test-autodeploy"

console.log "AUTODEPLOY", server


# git config --get remote.origin.url

# sets up the git repo on the server, based on the current git remote
# installs the git remote to match branches?

# wait a minute, what about the branch? is it 1:1?
# no, you just create one, and give it a name
# hmm.... it needs a name, no?

# you're going to forget its there :)


# gets the repo url for the current directory
repourl = (dir, cb) ->
  exec "git config --get remote.origin.url", {cwd:dir}, (err, stdout, stderr) ->
    if err? then return cb(new Error("Could not find git url"))
    cb null, stdout

install = (server, cb) ->
  repourl process.cwd(), (err, url) ->
    if err? then return cb err

    command = """
      this is my string
    """

    console.log url, command

    #spawn 'ssh', ['-tt', 'xxx']

install server, (err) ->
  if err? 
    console.log err.message
    process.exit 1
  console.log err, "Done"
