(function() {
  var __hasProp = Object.prototype.hasOwnProperty;
  window.API = {
    services: {
      zemanta: {
        box: 'Enter a block of text here &mdash; for example, a portion\
                    of a newspaper article &mdash; and see what Creative Commons\
                    images and related articles Zemanta would provide alongside.',
        description: 'Zemanta is a service that finds names, locations, photos,\
                    links and other material based on a chunk of text.',
        mode: 'text'
      },
      truveo: {
        box: 'Enter video keywords:',
        description: 'Truveo is a huge database of online videos.',
        mode: 'line'
      },
      opencongress: {
        box: 'Enter the last name of a Member of Congress:',
        description: 'A general resource on Congress, produced by the Participatory\
                    Politics Foundation and the Sunlight Foundation.',
        mode: 'line'
      },
      guardian: {
        box: 'Enter anything that might appear in a story, and see what\
                    related articles the Guardian API would suggest.',
        description: 'This API lets you mine The Guardian\'s article database.',
        mode: 'line'
      },
      oilreporter: {
        box: '',
        description: 'Oil Reporter is a new effort to crowdsource oil sightings\
                    along the Gulf coast.',
        mode: 'none'
      },
      twitter: {
        box: 'Enter a term to search for on Twitter, and see what the\
                    community is saying about it.',
        description: 'How might you mine the Twitterverse? With Twitter\'s API.',
        mode: 'line'
      },
      googlemaps: {
        box: 'Enter a location to get a map:',
        description: 'The Google Maps API is one of the oldest and most widely\
                    used APIs in existence.',
        mode: 'gmaps line',
        custom: true
      },
      freebase: {
        box: 'Enter a term to find with Freebase:',
        description: 'Freebase is a massive, collaboratively-edited database of\
                    cross-linked data.',
        mode: 'line'
      },
      calais: {
        box: 'Enter a block of text here &mdash; for example, a portion\
                    of a newspaper article &mdash; to see what entities are extracted.',
        description: 'OpenCalais finds entities (people, places, organizations, terms)\
                    within a document, and connects them to the web of linked data.',
        mode: 'text'
      }
    },
    initialize: function() {
      $('#go').click(API.go);
      $('#picker').bind('change', API.change);
      $('#line').keypress(function(e) {
        if (e.keyCode === 13) {
          return API.go();
        }
      });
      return API.change('freebase');
    },
    change: function(service) {
      var api;
      service = _.isString(service) ? service : $('#picker').val();
      api = API.services[service];
      API.current = api;
      document.body.className = ("" + (api.mode) + "_mode");
      $('#box_label').html(api.box);
      $('#description').html(api.description);
      $('#results').html('');
      return API.getInput().focus();
    },
    go: function() {
      var api, text;
      api = $('#picker').val();
      text = API.getInput().val();
      return API.services[api].custom ? API[api](text) : API.fetch(api, text);
    },
    getInput: function() {
      return API.current.mode === 'text' ? $('#text') : $('#line');
    },
    render: function(data) {
      return $('#results').html(API.table(data));
    },
    fetch: function(api, value) {
      var success;
      $('#spinner').show();
      success = function(response) {
        $('#spinner').hide();
        if ((typeof console === "undefined" || console === null) ? undefined : console.log) {
          console.log(response);
        }
        return API[("" + (api) + "Complete")](response);
      };
      return $.post("/api/" + (api) + ".json", {
        text: value
      }, success, 'json');
    },
    googlemaps: function(text) {
      var geocoder, latlng, map, options;
      $('#results').html('<div id="map"></div>');
      geocoder = new google.maps.Geocoder();
      latlng = new google.maps.LatLng(-34.397, 150.644);
      options = {
        zoom: 13,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.SATELLITE
      };
      map = new google.maps.Map($('#map')[0], options);
      return geocoder.geocode({
        address: text
      }, function(results, status) {
        var loc;
        if (status === google.maps.GeocoderStatus.OK) {
          loc = results[0].geometry.location;
          map.setCenter(loc);
          return new google.maps.Marker({
            map: map,
            position: loc
          });
        } else {
          return alert("Geocode was not successful for the following reason: " + (status));
        }
      });
    },
    zemantaComplete: function(response) {
      var articles, images, keywords;
      images = {
        title: "Images",
        headers: ["Description", "Image"],
        rows: _.map(response.images, function(image) {
          return [image.description, ("<img src='" + (image.url_m) + "' width='" + (image.url_m_w) + "' height='" + (image.url_m_h) + "' />")];
        })
      };
      articles = {
        title: "Articles",
        headers: ["Title", "Link", "Publication Date"],
        rows: _.map(response.articles, function(article) {
          return [
            article.title, {
              url: article.url,
              text: article.url
            }, article.published_datetime
          ];
        })
      };
      keywords = {
        title: "Keywords",
        headers: ["Keyword", "Confidence"],
        rows: _.map(response.keywords, function(keyword) {
          return [keyword.name, keyword.confidence];
        })
      };
      return API.render({
        tables: [images, articles, keywords]
      });
    },
    truveoComplete: function(response) {
      var videos;
      if (!(response.response.data.results.videoSet.videos)) {
        return alert('No related videos were found.');
      }
      videos = {
        title: "Videos",
        headers: ["Title", "Channel", "Description", "Video"],
        rows: _.map(response.response.data.results.videoSet.videos, function(video) {
          return [video.title, video.channel, video.description, video.videoPlayerEmbedTag];
        })
      };
      return API.render({
        tables: [videos]
      });
    },
    opencongressComplete: function(response) {
      var articles, news, people;
      if (!(response.people)) {
        return alert("No member of Congress by that name could be found.");
      }
      people = {
        title: "Members of Congress",
        headers: ["Name", "Website", "Phone", "Office", "Religion"],
        rows: _.map(response.people, function(person) {
          return [
            person.name, {
              url: person.website,
              text: person.website
            }, person.phone, person.congress_office, person.religion
          ];
        })
      };
      news = _.flatten(_.map(response.people, function(person) {
        return person.recent_news;
      }));
      articles = {
        title: "Articles",
        headers: ["Title", "Source", "Excerpt", "Link"],
        rows: _.map(news, function(article) {
          return [
            article.title, article.source, article.excerpt, {
              url: article.url,
              text: article.url
            }
          ];
        })
      };
      return API.render({
        tables: [people, articles]
      });
    },
    guardianComplete: function(response) {
      var articles;
      if (!(response.response.results.length)) {
        return alert("No related articles were found.");
      }
      articles = {
        title: "Articles",
        headers: ["Title", "Section", "Excerpt", "Link"],
        rows: _.map(response.response.results, function(article) {
          return [
            article.webTitle, article.sectionName, article.fields.trailText + '...', {
              url: article.webUrl,
              text: article.webUrl
            }
          ];
        })
      };
      return API.render({
        tables: [articles]
      });
    },
    oilreporterComplete: function(response) {
      var reports;
      reports = {
        title: "Reports",
        headers: ["Description", "Wildlife", "Oil", "Lat/Lng", "Date"],
        rows: _.map(response, function(report) {
          return [report.description, report.wildlife, report.oil, report.latitude + ' / ' + report.longitude, report.created_at];
        })
      };
      return API.render({
        tables: [reports]
      });
    },
    twitterComplete: function(response) {
      var tweets;
      tweets = {
        title: "Tweets",
        headers: ["User", "Picture", "Tweet"],
        rows: _.map(response.results, function(tweet) {
          return [tweet.from_user, "<img width='48' height='48' src='" + tweet.profile_image_url + "' />", tweet.text];
        })
      };
      return API.render({
        tables: [tweets]
      });
    },
    freebaseComplete: function(response) {
      var results;
      results = {
        title: "Results",
        headers: ["Name", "Image", "Relevance", "Categories", "Link"],
        rows: _.map(response.result, function(item) {
          var pic, types, url;
          types = _.map(item.type, function(el) {
            return el.name;
          });
          url = "http://www.freebase.com/view" + item.id;
          pic = "<img src='http://www.freebase.com/api/trans/image_thumb/guid/" + item.guid.substring(1) + "?maxwidth=150&maxheight=150' />";
          return [
            item.name, pic, item['relevance:score'], types.join(', '), {
              url: url,
              text: url
            }
          ];
        })
      };
      return API.render({
        tables: [results]
      });
    },
    calaisComplete: function(response) {
      var _a, _b, _c, _d, hash, rows, sets, tables, title, val;
      sets = {};
      _a = response;
      for (hash in _a) {
        if (!__hasProp.call(_a, hash)) continue;
        val = _a[hash];
        if (('Category' === (_b = val._type) || 'Company' === _b || 'Organization' === _b || 'City' === _b || 'Person' === _b || 'IndustryTerm' === _b || 'NaturalFeature' === _b || 'Country' === _b || 'Facility' === _b || 'Region' === _b || 'Product' === _b)) {
          sets[val._type] || (sets[val._type] = []);
          sets[val._type].push([val.name, val.relevance, val.instances[0].detection]);
        }
      }
      tables = (function() {
        _c = []; _d = sets;
        for (title in _d) {
          if (!__hasProp.call(_d, title)) continue;
          rows = _d[title];
          _c.push({
            title: title,
            headers: ["Name", "Relevance", "Occurrence"],
            rows: rows
          });
        }
        return _c;
      })();
      return API.render({
        tables: tables
      });
    },
    table: _.template("<% _.each(tables, function(table) { %>\n  <h3><%= table.title %></h3>\n  <table>\n    <thead>\n      <tr>\n        <% _.each(table.headers, function(header) { %>\n          <th><%= header %></th>\n        <% }); %>\n      </tr>\n    </thead>\n    <tbody>\n      <% _.each(table.rows, function(row) { %>\n        <tr>\n          <% _.each(row, function(col) { %>\n            <td class=\"col\">\n            <% if (col && col.url) { %>\n              <a href=\"<%= col.url %>\" target=\"_blank\"><%= col.text %></a>\n            <% } else { %>\n              <%= col %>\n            <% } %>\n            </td>\n          <% }); %>\n        </tr>\n      <% }); %>\n    </tbody>\n  </table>\n<% }); %>")
  };
  $(API.initialize);
})();
