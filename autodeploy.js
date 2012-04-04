(function() {
  var args, cp, exec, install, name, repo, repourl, server, spawn;

  cp = require('child_process');

  spawn = cp.spawn;

  exec = cp.exec;

  args = process.argv.slice(2);

  server = args[0];

  name = args[1];

  repo = args[2];

  server = "root@dev.i.tv";

  name = "test-autodeploy";

  console.log("AUTODEPLOY", server);

  repourl = function(dir, cb) {
    return exec("git config --get remote.origin.url", {
      cwd: dir
    }, function(err, stdout, stderr) {
      if (err != null) return cb(new Error("Could not find git url"));
      return cb(null, stdout);
    });
  };

  install = function(server, cb) {
    return repourl(process.cwd(), function(err, url) {
      var command;
      if (err != null) return cb(err);
      command = "this is my string";
      return console.log(url, command);
    });
  };

  install(server, function(err) {
    if (err != null) {
      console.log(err.message);
      process.exit(1);
    }
    return console.log(err, "Done");
  });

}).call(this);
