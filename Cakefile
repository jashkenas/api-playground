{print}:        require 'sys'
{spawn, exec}: require 'child_process'

task 'build', 'Build and watch the CoffeeScript source files', ->
  coffee: spawn 'coffee', ['-cw', '-o', 'lib', 'src']
  coffee.stdout.addListener 'data', (data) -> print data.toString()

task 'deploy', 'Deploy to Linode', ->
  exec "rsync -av --progress --inplace --rsh='ssh -p9977' . jashkenas@ashkenas.com:/home/jashkenas/sites/api_playground", ->
    puts "Deployed..."
    exec "ssh -t -p 9977 jashkenas@ashkenas.com 'nohup node sites/api_playground/lib/app.js &; exit'", ->
      puts "Restarted..."
