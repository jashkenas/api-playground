require 'express'
http: require 'express/express/http'
path: require 'path'
sys:  require 'sys'
fs:   require 'fs'

root_dir: path.normalize __dirname + '/..'

configure ->
  use Static
  use Logger
  set 'root', root_dir

urls: {
  zemanta:      "http://api.zemanta.com/services/rest/0.0"
  truveo:       "http://xml.truveo.com/apiv3"
  opencongress: "http://www.opencongress.org/api/people"
  guardian:     "http://content.guardianapis.com/search"
  oilreporter:  "http://oilreporter.org/reports.json"
  twitter:      "http://search.twitter.com/search.json"
  freebase:     "http://www.freebase.com/api/service/search"
}

keys: JSON.parse fs.readFileSync(root_dir + '/config/keys.json').toString()

get '/', ->
  @render 'index.html.ejs', {layout: no}

get '/api/twitter.json', ->
  http.get urls.twitter, {
    q:    @param('text')
    rpp:  50
  }, respond this

get '/api/zemanta.json', ->
  http.post urls.zemanta, {
    api_key:  keys.zemanta
    method:   'zemanta.suggest'
    format:   'json'
    text:     @param 'text'
  }, respond this

get '/api/truveo.json', ->
  http.get urls.truveo, {
    appid:            keys.truveo
    method:           'truveo.videos.getVideos'
    query:            @param 'text'
    results:          10
    showRelatedItems: 1
    showAdult:        0
    format:           'json'
  }, respond this

get '/api/opencongress.json', ->
  http.get urls.opencongress, {
    key:        keys.opencongress
    last_name:  capitalize @param 'text'
    format:     'json'
  }, respond this

get '/api/guardian.json', ->
  http.get urls.guardian, {
    q:              @param 'text'
    'api-key':      keys.guardian
    'show-fields':  'all'
    format:         'json'
  }, respond this

get '/api/oilreporter.json', ->
  http.get urls.oilreporter, {
    api_key: keys.oilreporter
  }, respond this

get '/api/freebase.json', ->
  http.get urls.freebase, {
    query: @param 'text'
  }, respond this

respond: (request) ->
  (err, body, response) =>
    throw err if err
    request.respond 200, body

capitalize: (s) ->
  s.charAt(0).toUpperCase() + s.substring(1).toLowerCase()

process.addListener 'uncaughtException', (err) ->
  sys.puts "Uncaught Exception: ${err.toString()}"

run(2560)
