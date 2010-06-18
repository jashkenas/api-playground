window.API: {

  services : {
    zemanta       : {box: 'Enter a block of text here, say an article from the New York Times, and see what Creative Commons images and related articles Zemanta could provide alongside.', description: 'Zemanta is a service that finds names, locations, photos, links and other material based on a chunk of text.', mode : 'text'}
    truveo        : {box: 'Enter video keywords:', description: 'Truveo is a huge database of online videos.', mode : 'line'}
    opencongress  : {box: 'Enter the last name of a Member of Congress:', description: 'A general resource on Congress, produced by the Participatory Politics Foundation and the Sunlight Foundation.', mode : 'line'}
    guardian      : {box: 'Enter anything that might appear in a story, and see what related articles the Guardian API would suggest.', description: 'This API lets you mine The Guardian\'s article database.', mode : 'line'}
    oilreporter   : {box: '', description :'Oil Reporter is a new effort to crowdsource oil sightings along the Gulf coast.', mode : 'none'}
    twitter       : {box: 'Enter a term to search for on Twitter, and see what the community is saying about it.', description: 'How might you mine the Twitterverse? With Twitter\'s API.', mode : 'line'}
    googlemaps    : {box: 'Enter a location to get a map:', description: 'The Google Maps API is one of the oldest and most widely used APIs in existence.', mode : 'gmaps line', custom : yes}
  }

  initialize: ->
    $('#go').click API.go
    $('#picker').bind 'change', API.change
    $('#line').keypress (e) -> (API.go() if e.keyCode is 13)
    API.change 'guardian'

  change: (service) ->
    service: if _.isString(service) then service else $('#picker').val()
    api: API.services[service]
    API.current: api
    document.body.className: "${api.mode}_mode"
    $('#box_label').html api.box
    $('#description').html api.description
    $('#results').html ''
    API.getInput().focus()

  go: ->
    api:  $('#picker').val()
    text: API.getInput().val()
    if API.services[api].custom then API[api](text) else API.fetch api, text

  getInput: ->
    if API.current.mode is 'text' then $('#text') else $('#line')

  render: (data) ->
    $('#results').html API.table data

  fetch: (api, value) ->
    $.getJSON "/api/${api}.json", {text: value}, API["${api}Complete"]
    $('#spinner').show()

  googlemaps: (text) ->
    geocoder: new google.maps.Geocoder()
    latlng:   new google.maps.LatLng(-34.397, 150.644)
    options:  {zoom: 13, center: latlng, mapTypeId: google.maps.MapTypeId.SATELLITE}
    map:      new google.maps.Map $('#results')[0], options
    geocoder.geocode {address : text}, (results, status) ->
      if status is google.maps.GeocoderStatus.OK
        loc: results[0].geometry.location
        map.setCenter loc
        new google.maps.Marker {map: map, position: loc}
      else
        alert "Geocode was not successful for the following reason: $status"

  zemantaComplete: (response) ->
    $('#spinner').hide()
    images: {
      title   : "Images"
      headers : ["Description", "Image"]
      rows    : _.map response.images, (image) ->
        [image.description, "<img src='$image.url_m' width='$image.url_m_w' height='$image.url_m_h' />"]
    }
    articles: {
      title   : "Articles"
      headers : ["Title", "Link", "Publication Date"]
      rows    : _.map response.articles, (article) ->
        [article.title, {url: article.url, text: article.url}, article.published_datetime]
    }
    keywords: {
      title   : "Keywords"
      headers : ["Keyword", "Confidence"]
      rows    : _.map response.keywords, (keyword) ->
        [keyword.name, keyword.confidence]
    }
    API.render {tables: [images, articles, keywords]}

  truveoComplete: (response) ->
    $('#spinner').hide()
    videos: {
      title   : "Videos"
      headers : ["Title", "Channel", "Description", "Video"]
      rows    : _.map response.response.data.results.videoSet.videos, (video) ->
        [video.title, video.channel, video.description, video.videoPlayerEmbedTag]
    }
    API.render {tables: [videos]}

  opencongressComplete: (response) ->
    $('#spinner').hide()
    people: {
      title   : "Members of Congress"
      headers : ["Name", "Website", "Phone", "Office", "Religion"]
      rows    : _.map response.people, (person) ->
        [person.name, {url: person.website, text: person.website}, person.phone, person.congress_office, person.religion]
    }
    news: _.flatten _.map response.people, (person) -> person.recent_news
    articles: {
      title   : "Articles"
      headers : ["Title", "Source", "Excerpt", "Link"]
      rows    : _.map news, (article) ->
        [article.title, article.source, article.excerpt, {url: article.url, text: article.url}]
    }
    API.render {tables: [people, articles]}

  guardianComplete: (response) ->
    $('#spinner').hide()
    articles: {
      title   : "Articles"
      headers : ["Title", "Section", "Excerpt", "Link"]
      rows    : _.map response.response.results, (article) ->
        [article.webTitle, article.sectionName, article.fields.trailText + '...', {url: article.webUrl, text: article.webUrl}]
    }
    API.render {tables: [articles]}

  oilreporterComplete: (response) ->
    $('#spinner').hide()
    reports: {
      title   : "Reports"
      headers : ["Description", "Wildlife", "Oil", "Lat/Lng", "Date"]
      rows    : _.map response, (report) ->
        [report.description, report.wildlife, report.oil, report.latitude + ' / ' + report.longitude, report.created_at]
    }
    API.render {tables : [reports]}

  twitterComplete: (response) ->
    $('#spinner').hide()
    tweets: {
      title   : "Tweets"
      headers : ["User", "Picture", "Tweet"]
      rows    : _.map response.results, (tweet) ->
        [tweet.from_user, "<img width='48' height='48' src='" + tweet.profile_image_url + "' />", tweet.text]
    }
    API.render {tables : [tweets]}

  table: _.template """
    <% _.each(tables, function(table) { %>
      <h3><%= table.title %></h3>
      <table>
        <thead>
          <tr>
            <% _.each(table.headers, function(header) { %>
              <th><%= header %></th>
            <% }); %>
          </tr>
        </thead>
        <tbody>
          <% _.each(table.rows, function(row) { %>
            <tr>
              <% _.each(row, function(col) { %>
                <td class="col">
                <% if (col && col.url) { %>
                  <a href="<%= col.url %>" target="_blank"><%= col.text %></a>
                <% } else { %>
                  <%= col %>
                <% } %>
                </td>
              <% }); %>
            </tr>
          <% }); %>
        </tbody>
      </table>
    <% }); %>
                    """

}

$ API.initialize
