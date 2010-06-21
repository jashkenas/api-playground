{print}:        require 'sys'
{spawn, exec}: require 'child_process'

task 'build', 'Build and watch the CoffeeScript source files', ->
  coffee: spawn 'coffee', ['-cw', '-o', 'lib', 'src']
  coffee.stdout.addListener 'data', (data) -> print data.toString()

task 'deploy', 'Deploy to Linode', ->
  exec "rsync -av --progress --inplace --rsh='ssh -p9977' . jashkenas@ashkenas.com:/home/jashkenas/sites/api_playground", (err, stdout) ->
    puts "Deployed..."
    exec "ssh -p 9977 jashkenas@ashkenas.com 'pkill -n node; EXPRESS_ENV=production nohup node sites/api_playground/lib/app.js > /var/log/node.log 2>&1 &'", (err, stdout, stderr) ->
      puts "Restarted..."
