
/*
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
*/

(function() {
  var APP, CONFIG, PREFIX, action, addGitRemote, args, create, deploy, done, exec, fs, local, logs, mainConfig, namedConfig, path, readConfig, readNamedConfig, reponame, restart, serviceId, spawn, ssh, start, stop, usage, writeConfig, _ref;

  APP = "gogogo";

  PREFIX = "ggg";

  CONFIG = ".ggg";

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  fs = require('fs');

  path = require('path');

  reponame = function(dir, cb) {
    return exec("git config --get remote.origin.url", {
      cwd: dir
    }, function(err, stdout, stderr) {
      var url;
      if (err != null) {
        return cb(null, path.basename(path.dirname(dir)));
      } else {
        url = stdout.replace("\n", "");
        return cb(null, path.basename(url).replace(".git", ""));
      }
    });
  };

  writeConfig = function(f, obj, cb) {
    return fs.mkdir(path.dirname(f), function(err) {
      return fs.writeFile(f, "module.exports = " + JSON.stringify(obj), 0775, cb);
    });
  };

  readConfig = function(f, cb) {
    return cb(null, require(f));
  };

  namedConfig = function(name) {
    return path.join(process.cwd(), CONFIG, name + ".js");
  };

  mainConfig = function() {
    return path.join(process.cwd(), CONFIG, "_main.js");
  };

  readNamedConfig = function(name, cb) {
    return readConfig(namedConfig(name), cb);
  };

  serviceId = function(repoName, name) {
    return repoName + "_" + name;
  };

  addGitRemote = function(name, url, cb) {
    return exec("git remote rm " + name, function(err, stdout, stderr) {
      return exec("git remote add " + name + " " + url, function(err, stdout, stderr) {
        if (err != null) return cb(err);
        return cb();
      });
    });
  };

  ssh = function(server, commands, cb) {
    return local('ssh', [server, commands], function(err) {
      if (err != null) return cb(new Error("SSH Command Failed"));
      return cb();
    });
  };

  local = function(command, args, cb) {
    var process;
    process = spawn(command, args);
    process.stdout.on('data', function(data) {
      return console.log(data.toString());
    });
    process.stderr.on('data', function(data) {
      return console.log(data.toString());
    });
    return process.on('exit', function(code) {
      if (code) return cb(new Error("Command Failed"));
      return cb();
    });
  };

  create = function(name, server, cb) {
    console.log("GOGOGO CREATING!");
    console.log(" name: " + name);
    console.log(" server: " + server);
    return reponame(process.cwd(), function(err, rn) {
      var deployurl, hook, hookfile, id, log, parent, remote, repo, service, upstart, wd;
      if (err != null) return cb(err);
      id = serviceId(rn, name);
      parent = "$HOME/" + PREFIX;
      repo = wd = "" + parent + "/" + id;
      upstart = "/etc/init/" + id + ".conf";
      log = "log.txt";
      hookfile = "" + repo + "/.git/hooks/post-receive";
      deployurl = "ssh://" + server + "/~/" + PREFIX + "/" + id;
      console.log(" id: " + id);
      console.log(" repo: " + repo);
      console.log(" remote: " + deployurl);
      service = "description '" + id + "'\nstart on startup\nchdir " + repo + "\nrespawn\nrespawn limit 5 5 \nexec npm start >> " + log + " 2>&1";
      hook = "read oldrev newrev refname\necho 'GOGOGO HOOK!'\necho \\$newrev\ncd " + repo + "/.git\nGIT_WORK_TREE=" + repo + " git reset --hard \\$newrev || exit 1;";
      remote = "mkdir -p " + repo + "\ncd " + repo + "\ngit init\ngit config receive.denyCurrentBranch ignore\n\necho \"" + service + "\" > " + upstart + "\n\necho \"" + hook + "\" > " + hookfile + "\nchmod +x " + hookfile;
      return ssh(server, remote, function(err) {
        var config;
        if (err != null) return cb(err);
        config = {
          name: name,
          server: server,
          id: id,
          repoUrl: deployurl,
          repo: repo
        };
        return writeConfig(namedConfig(name), config, function(err) {
          if (err != null) return cb(new Error("Could not write config file"));
          console.log("-------------------------------");
          console.log("deploy: 'gogogo " + name + " BRANCH'");
          return cb();
        });
      });
    });
  };

  deploy = function(name, branch, cb) {
    return readNamedConfig(name, function(err, config) {
      if (err != null) return cb(err);
      console.log("PUSHING");
      return local("git", ["push", config.repoUrl, branch], function(err) {
        var command;
        if (err != null) return cb(err);
        command = "echo 'INSTALLING'\ncd " + config.repo + "\nnpm install --unsafe-perm || exit 1;\necho 'RESTARTING'\nstop " + config.id + "\nstart " + config.id;
        return ssh(config.server, command, cb);
      });
    });
  };

  restart = function(name, cb) {
    return readNamedConfig(name, function(err, config) {
      if (err != null) return cb(err);
      return ssh(config.server, "stop " + config.id + "; start " + config.id, cb);
    });
  };

  stop = function(name, cb) {
    return readNamedConfig(name, function(err, config) {
      if (err != null) return cb(err);
      return ssh(config.server, "stop " + config.id + ";", cb);
    });
  };

  start = function(name, cb) {
    return readNamedConfig(name, function(err, config) {
      if (err != null) return cb(err);
      return ssh(config.server, "start " + config.id + ";", cb);
    });
  };

  logs = function(name, cb) {
    return readNamedConfig(name, function(err, config) {
      var log;
      if (err != null) return cb(err);
      log = config.repo + "/log.txt";
      console.log("Tailing " + log + "... Control-C to exit");
      console.log("-------------------------------------------------------------");
      return ssh(config.server, "tail -f " + log, cb);
    });
  };

  done = function(err) {
    if (err != null) {
      console.log(err.message);
      process.exit(1);
    }
    return console.log("OK");
  };

  usage = function() {
    return console.log("Usage: gogogo create NAME USER@SERVER");
  };

  args = process.argv.slice(2);

  action = args[0];

  switch (action) {
    case "add":
      create(args[1], args[2], done);
      break;
    case "restart":
      restart(args[1], done);
      break;
    case "start":
      start(args[1], done);
      break;
    case "stop":
      stop(args[1], done);
      break;
    case "logs":
      logs(args[1], done);
      break;
    case "deploy":
      deploy(args[1], args[2], done);
      break;
    default:
      usage();
  }

}).call(this);
