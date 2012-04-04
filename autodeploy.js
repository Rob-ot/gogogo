
/*
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
*/

(function() {
  var APP, CONF, DEFAULT, args, create, deploy, exec, fs, name, path, read, repo, repourl, server, spawn, _ref;

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  fs = require('fs');

  path = require('path');

  APP = "woot";

  CONF = "woot.json";

  DEFAULT = "default";

  args = process.argv.slice(2);

  server = args[0];

  name = args[1];

  repo = args[2];

  server = "root@dev.i.tv";

  name = "test-autodeploy";

  repourl = function(dir, cb) {
    return exec("git config --get remote.origin.url", {
      cwd: dir
    }, function(err, stdout, stderr) {
      if (err != null) return cb(new Error("Could not find git url"));
      return cb(null, stdout.replace("\n", ""));
    });
  };

  read = function(f, cb) {
    return fs.readFile(f, function(err, data) {
      var parsed;
      if (err != null) return cb(new Error("Missing: " + f));
      try {
        parsed = JSON.parse(data);
      } catch (e) {
        return cb(new Error("JSON Error: " + e.message));
      }
      return cb(null, parsed);
    });
  };

  create = function(server, name, cb) {
    console.log("CREATING");
    console.log(" name: " + name);
    console.log(" server: " + server);
    return repourl(process.cwd(), function(err, url) {
      var commands, logPath, repoPath, service, ssh, uniqueName, upstartPath;
      if (err != null) return cb(err);
      console.log(" repo: " + url);
      uniqueName = APP + "_" + path.basename(url).replace(".git", "") + "_" + name;
      repoPath = "~/woot/" + uniqueName;
      upstartPath = "/etc/init/" + uniqueName + ".conf";
      logPath = "" + repoPath + "/log.txt";
      console.log(" id: " + uniqueName);
      console.log(" path: " + repoPath);
      service = "description '" + uniqueName + "'\nstart on startup\nchdir " + repoPath + "\nrespawn\nrespawn limit 5 5 \nexec bash woot.sh >> " + logPath;
      commands = "cd ~\nmkdir -p " + repoPath + "\ngit clone " + url + " " + repoPath + "\necho \"" + service + "\" > " + upstartPath;
      console.log("---------------------");
      ssh = spawn('ssh', [server, commands]);
      ssh.stdout.on('data', function(data) {
        return console.log(data.toString());
      });
      ssh.stderr.on('data', function(data) {
        return console.log(data.toString());
      });
      return ssh.on('exit', function(code) {
        if (code) cb(new Error("Failed"));
        return cb();
      });
    });
  };

  deploy = function(name, cb) {
    console.log("DEPLOYING");
    return console.log(" name: " + name);
  };

}).call(this);
