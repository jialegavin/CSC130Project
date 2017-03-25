/***************************
This is JavaScript (JS), the programming language that powers the web (and this is a comment, which you can delete).

To use this file, link it to your markup by placing a <script> in the <body> of your HTML file:

  <body>
    <script src="script.js"></script>

replacing "script.js" with the name of this JS file.

Learn more about JavaScript at

https://developer.mozilla.org/en-US/Learn/JavaScript
***************************/

var NEWS_SOURCE_ENDPOINT = "https://cors-anywhere.herokuapp.com/https://newsapi.org/v1/sources"
var NEWS_ARTICLE_ENDPOINT = "https://cors-anywhere.herokuapp.com/https://newsapi.org/v1/articles"
var NEWS_API = "4c93323d4597439b944fb2dde4f41220"

$(document).ready(function() {
  var coords = undefined
  
  if(navigator.geolocation) {
    navigator.geolocation.watchPosition(function(position) {
      coords = position.coords
      console.log(coords)
    })
  }
  newsSources()
  //newsArticles("bbc-news")
})

function newsSources(language, category, country) {
  var settings = {
    data: {
      language:language,
      category:category,
      country:country
    },
    success: searchSuccessSource,
    //error: searchError
  }
  jQuery.ajax(NEWS_SOURCE_ENDPOINT, settings)
}

function newsArticles(source, sort) {
  var settings = {
    data: {
      source:source,
      apiKey:NEWS_API,
      sortBy:sort
    },
    success: searchSuccess,
    //error: searchError
  }
  jQuery.ajax(NEWS_ARTICLE_ENDPOINT, settings)
}



function searchSuccessSource(data, textStatus, jqXHR) {
  console.log(data)
  data.sources.forEach(addSearchResult)
}


function addSearchResult(source) {
  var sourceDiv = $("<div />", {'class': 'source'})
  var sourceHeaderDiv = $("<div />", {'class': 'sourceHeader'})
  var name = $("<span class=\"name\">"+ source.name +"</span>")

  var description = $("<span class=\"name\">"+ source.description +"</span>")

  /*
  var image = $("<img />", {
    src: '"' + source.urlsToLogo.small + '"'
  })
  */
  //sourceDiv.append(image)
  sourceHeaderDiv.append(name)
  sourceDiv.append(sourceHeaderDiv)
  sourceDiv.append(description)
  sourceDiv.appendTo($("#search-results"))
}
