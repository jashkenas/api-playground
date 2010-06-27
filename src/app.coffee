# Load Express and Node.js modules we rely on.
require 'express'
http: require 'express/express/http'
path: require 'path'
sys:  require 'sys'
fs:   require 'fs'


# Determine the absolute path to the root directory of the app.
root_dir: path.normalize __dirname + '/..'


# Configure Express.
configure ->
  use Static
  use Logger
  set 'root', root_dir


# The list of remote URLs for the APIs that we hit.
urls: {
  zemanta:      "http://api.zemanta.com/services/rest/0.0"
  truveo:       "http://xml.truveo.com/apiv3"
  opencongress: "http://www.opencongress.org/api/people"
  guardian:     "http://content.guardianapis.com/search"
  oilreporter:  "http://oilreporter.org/reports.json"
  twitter:      "http://search.twitter.com/search.json"
  freebase:     "http://www.freebase.com/api/service/search"
  calais:       "http://api.opencalais.com/enlighten/rest"
}


# Load the API keys out of our secret keys.json file. Format is identical
# to `urls`, above.
keys: JSON.parse fs.readFileSync(root_dir + '/config/keys.json').toString()


# The ApiPlayground.org homepage.
get '/', ->
  @render 'index.html.ejs', {layout: no}


# Call to the Twitter search API.
get '/api/twitter.json', ->
  http.get urls.twitter, {
    q:    @param('text')
    rpp:  50
  }, respond this


# Call to the Zemanta "suggest related content" API.
get '/api/zemanta.json', ->
  http.post urls.zemanta, {
    api_key:  keys.zemanta
    method:   'zemanta.suggest'
    format:   'json'
    text:     @param 'text'
  }, respond this


# Call to the Truveo video search API.
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


# Call to the OpenCongress Senator and Representative lookup API.
get '/api/opencongress.json', ->
  http.get urls.opencongress, {
    key:        keys.opencongress
    last_name:  capitalize @param 'text'
    format:     'json'
  }, respond this


# Call to the Guardian article search API.
get '/api/guardian.json', ->
  http.get urls.guardian, {
    q:              @param 'text'
    'api-key':      keys.guardian
    'show-fields':  'all'
    format:         'json'
  }, respond this


# Call to the OilReporter beach reports API.
get '/api/oilreporter.json', ->
  http.get urls.oilreporter, {
    api_key: keys.oilreporter
  }, respond this


# Call to the Freebase linked data search API.
get '/api/freebase.json', ->
  http.get urls.freebase, {
    query: @param 'text'
  }, respond this


# Call to the OpenCalais entity extraction API.
get '/api/calais.json', ->
  http.post urls.calais, {
    licenseID:  keys.calais
    content:    @param 'text'
    paramsXML:  '''
                <c:params xmlns:c="http://s.opencalais.com/1/pred/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                  <c:processingDirectives c:contentType="text/raw" c:outputFormat="application/json" c:docRDFaccesible="false" ></c:processingDirectives>
                  <c:userDirectives c:allowDistribution="false" c:allowSearch="false" c:submitter="The API Playground"></c:userDirectives>
                </c:params>
                '''
  }, respond this


# Create a function that defers the response to a given request.
respond: (request) ->
  (err, body, response) =>
    throw err if err
    request.respond 200, body


# Helper function to capitalize a word.
capitalize: (s) ->
  s.charAt(0).toUpperCase() + s.substring(1).toLowerCase()


# Catch and log any exceptions that may bubble to the top.
process.addListener 'uncaughtException', (err) ->
  sys.puts "Uncaught Exception: ${err.toString()}"


# Start the server.
run 2560
