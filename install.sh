# compile, then prepend the node shebang
node_modules/.bin/coffee -c .

echo "#!/usr/bin/env node" > run.js
cat gogogo.js >> run.js
