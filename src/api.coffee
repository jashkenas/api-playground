window.API: {

  services:  {
    zemanta: {
      box:          'Enter a block of text here &mdash; for example, a portion
                    of a newspaper article &mdash; and see what Creative Commons
                    images and related articles Zemanta would provide alongside.'
      description:  'Zemanta is a service that finds names, locations, photos,
                    links and other material based on a chunk of text.'
      mode:         'text'
    }
    truveo: {
      box:          'Enter video keywords:'
      description:  'Truveo is a huge database of online videos.'
      mode:         'line'
    }
    opencongress: {
      box:          'Enter the last name of a Member of Congress:'
      description:  'A general resource on Congress, produced by the Participatory
                    Politics Foundation and the Sunlight Foundation.'
      mode:         'line'
    }
    guardian: {
      box:          'Enter anything that might appear in a story, and see what
                    related articles the Guardian API would suggest.'
      description:  'This API lets you mine The Guardian\'s article database.'
      mode:         'line'
    }
    oilreporter: {
      box:          ''
      description:  'Oil Reporter is a new effort to crowdsource oil sightings
                    along the Gulf coast.'
      mode:         'none'
    }
    twitter: {
      box:          'Enter a term to search for on Twitter, and see what the
                    community is saying about it.'
      description:  'How might you mine the Twitterverse? With Twitter\'s API.'
      mode:         'line'
    }
    googlemaps: {
      box:          'Enter a location to get a map:'
      description:  'The Google Maps API is one of the oldest and most widely
                    used APIs in existence.'
      mode:         'gmaps line'
      custom:       yes
    }
    freebase: {
      box:          'Enter a term to find with Freebase:'
      description:  'Freebase is a centralized clearinghouse for linked data,
                    including all of Wikipedia.'
      mode:         'line'
    }
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
    $('#spinner').show()
    $.getJSON "/api/${api}.json", {text: value}, (response) ->
      $('#spinner').hide()
      API["${api}Complete"](response)

  googlemaps: (text) ->
    $('#results').html '<div id="map"></div>'
    geocoder: new google.maps.Geocoder()
    latlng:   new google.maps.LatLng(-34.397, 150.644)
    options:  {zoom: 13, center: latlng, mapTypeId: google.maps.MapTypeId.SATELLITE}
    map:      new google.maps.Map $('#map')[0], options
    geocoder.geocode {address:  text}, (results, status) ->
      if status is google.maps.GeocoderStatus.OK
        loc: results[0].geometry.location
        map.setCenter loc
        new google.maps.Marker {map: map, position: loc}
      else
        alert "Geocode was not successful for the following reason: $status"

  zemantaComplete: (response) ->
    images: {
      title:    "Images"
      headers:  ["Description", "Image"]
      rows:     _.map response.images, (image) ->
        [image.description, "<img src='$image.url_m' width='$image.url_m_w' height='$image.url_m_h' />"]
    }
    articles: {
      title:    "Articles"
      headers:  ["Title", "Link", "Publication Date"]
      rows:     _.map response.articles, (article) ->
        [article.title, {url: article.url, text: article.url}, article.published_datetime]
    }
    keywords: {
      title:    "Keywords"
      headers:  ["Keyword", "Confidence"]
      rows:     _.map response.keywords, (keyword) ->
        [keyword.name, keyword.confidence]
    }
    API.render {tables: [images, articles, keywords]}

  truveoComplete: (response) ->
    return alert 'No related videos were found.' unless response.response.data.results.videoSet.videos
    videos: {
      title:    "Videos"
      headers:  ["Title", "Channel", "Description", "Video"]
      rows:     _.map response.response.data.results.videoSet.videos, (video) ->
        [video.title, video.channel, video.description, video.videoPlayerEmbedTag]
    }
    API.render {tables: [videos]}

  opencongressComplete: (response) ->
    return alert "No member of Congress by that name could be found." unless response.people
    people: {
      title:    "Members of Congress"
      headers:  ["Name", "Website", "Phone", "Office", "Religion"]
      rows:     _.map response.people, (person) ->
        [person.name, {url: person.website, text: person.website}, person.phone, person.congress_office, person.religion]
    }
    news: _.flatten _.map response.people, (person) -> person.recent_news
    articles: {
      title:    "Articles"
      headers:  ["Title", "Source", "Excerpt", "Link"]
      rows:     _.map news, (article) ->
        [article.title, article.source, article.excerpt, {url: article.url, text: article.url}]
    }
    API.render {tables: [people, articles]}

  guardianComplete: (response) ->
    return alert "No related articles were found." unless response.response.results.length
    articles: {
      title:    "Articles"
      headers:  ["Title", "Section", "Excerpt", "Link"]
      rows:     _.map response.response.results, (article) ->
        [article.webTitle, article.sectionName, article.fields.trailText + '...', {url: article.webUrl, text: article.webUrl}]
    }
    API.render {tables: [articles]}

  oilreporterComplete: (response) ->
    reports: {
      title:    "Reports"
      headers:  ["Description", "Wildlife", "Oil", "Lat/Lng", "Date"]
      rows:     _.map response, (report) ->
        [report.description, report.wildlife, report.oil, report.latitude + ' / ' + report.longitude, report.created_at]
    }
    API.render {tables:  [reports]}

  twitterComplete: (response) ->
    tweets: {
      title:    "Tweets"
      headers:  ["User", "Picture", "Tweet"]
      rows:     _.map response.results, (tweet) ->
        [tweet.from_user, "<img width='48' height='48' src='" + tweet.profile_image_url + "' />", tweet.text]
    }
    API.render {tables:  [tweets]}

  freebaseComplete: (response) ->
    console.log response
    results: {
      title:    "Results"
      headers:  ["Name", "Image", "Relevance", "Categories", "Link"]
      rows:     _.map response.result, (item) ->
        types:  _.map item.type, (el) -> el.name
        url:    "http://www.freebase.com/view" + item.id
        pic:    "<img src='http://www.freebase.com/api/trans/image_thumb/guid/" + item.guid.substring(1) + "?maxwidth=150&maxheight=150' />"
        [item.name, pic, item['relevance:score'], types.join(', '), {url, text: url}]
    }
    API.render {tables: [results]}

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
