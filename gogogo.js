#!/usr/bin/env node

/*
The above is a hack to get the shebang in there correctly
CLI to automatically deploy stuff, kind of like heroku. 
Ubuntu only! (upstart)
*/

(function() {
  var APP, PREFIX, action, args, create, done, exec, fs, name, path, repourl, server, spawn, usage, _ref;

  APP = "gogogo";

  PREFIX = "ggg";

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  fs = require('fs');

  path = require('path');

  args = process.argv.slice(2);

  action = args[0];

  name = args[1];

  server = args[2];

  repourl = function(dir, cb) {
    return exec("git config --get remote.origin.url", {
      cwd: dir
    }, function(err, stdout, stderr) {
      if (err != null) return cb(new Error("Could not find git url"));
      return cb(null, stdout.replace("\n", ""));
    });
  };

  create = function(server, name, cb) {
    console.log("CREATING");
    console.log(" name: " + name);
    console.log(" server: " + server);
    return repourl(process.cwd(), function(err, url) {
      var deployurl, hook, hookfile, id, logfile, parent, remote, repo, service, ssh, upstart, wd;
      if (err != null) return cb(err);
      console.log(" repo: " + url);
      id = PREFIX + "_" + path.basename(url).replace(".git", "") + "_" + name;
      parent = "$HOME/" + PREFIX;
      wd = "" + parent + "/" + id;
      repo = wd + ".git";
      upstart = "/etc/init/" + id + ".conf";
      logfile = "log.txt";
      hookfile = "" + repo + "/hooks/post-receive";
      deployurl = "ssh://" + server + "/" + repo;
      console.log(" id: " + id);
      console.log(" repo: " + repo);
      console.log(" wd: " + wd);
      console.log(" remote: " + deployurl);
      service = "description '" + id + "'\nstart on startup\nchdir " + wd + "\nrespawn\nrespawn limit 5 5 \nexec npm start >> " + logfile + " 2>&1";
      hook = "#!/bin/sh\nGIT_WORK_TREE=" + wd + " git checkout -f\ncd " + wd + "\nnpm install\nstart " + id;
      remote = "mkdir -p " + wd + "\ngit clone --bare " + url + " " + repo + "\necho \"" + service + "\" > " + upstart + "\necho \"" + hook + "\" > " + hookfile + "\nchmod +x " + hookfile;
      console.log("---------------------");
      console.log(remote);
      console.log("---------------------");
      ssh = spawn('ssh', [server, remote]);
      ssh.stdout.on('data', function(data) {
        return console.log(data.toString());
      });
      ssh.stderr.on('data', function(data) {
        return console.log(data.toString());
      });
      return ssh.on('exit', function(code) {
        if (code) cb(new Error("Failed"));
        return exec("git remote rm " + name, function(err, stdout, stderr) {
          return exec("git remote add " + name + " " + deployurl, function(err, stdout, stderr) {
            if (err != null) return cb(err);
            return cb();
          });
        });
      });
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

  switch (action) {
    case "add":
      create(name, server, done);
      break;
    default:
      usage();
  }

}).call(this);
