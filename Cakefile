{spawn, exec}: require 'child_process'

task 'deploy', 'Deploy to Linode', ->
  exec "rsync -av --progress --inplace --rsh='ssh -p9977' . jashkenas@ashkenas.com:/home/jashkenas/sites/api_playground", ->
    puts "Deployed..."
    exec "ssh -t -p 9977 jashkenas@ashkenas.com 'pkill -n node; nohup node sites/api_playground/lib/app.js &; exit'", ->
      puts "Restarted..."
