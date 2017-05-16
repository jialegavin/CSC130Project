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
var article_sources = [];
var article_source_picked = [];
var id_for_nav = ['source_nav_1', 'source_nav_2', 'source_nav_3', 'source_nav_4', 'source_nav_5'];
var source_want_to_pick = [];
$(document).ready(function() {
  var coords = undefined

  if(navigator.geolocation) {
    navigator.geolocation.watchPosition(function(position) {
      coords = position.coords
      console.log(coords)
    })
  }
  newsSources();
  console.log(article_sources.length);
	$("#submitButton").on('click', function(){
		article_source_picked = source_want_to_pick;
	
		newsArticles(article_source_picked[0].id);
		changeNav();
		$('#chooseSourceDialog').modal('hide');
	});
});


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
  data.sources.forEach(addSearchResult);
  for(var i = 0; i < 5 && i < article_sources.length; i++) {
	article_source_picked.push(article_sources[i]);
  }
  newsArticles(article_source_picked[0].id);
  changeNav();
}


function addSearchResult(source) {
  article_sources.push(source);
  var sourceDiv = $("<button />", {'class': 'source col-sm-4 btn btn-default', 'id': article_sources.length - 1, 'data-toggle':"tooltip", 'data-placement':"bottom", 'title':source.name, 'type':"button"});
  sourceDiv.on('click', function(){
	var source = article_sources[this.id];
	if (this.classList.contains('active')) {
		var index = source_want_to_pick.indexOf(source);
		source_want_to_pick.splice(index, 1);
		this.classList.remove('active');
	} else {
		if(source_want_to_pick.length < 5) {
			source_want_to_pick.push(source);
			this.classList.add('active');
		} else {
			
		}
	}
	refreshTags();
  });
  
  var image = $("<img />", {
    'src': source.urlsToLogos.small, 'class': 'img-round', 'style': 'max-width: 100%; max-height: 100%;display: block; margin: auto;'});
  
  sourceDiv.append(image)
  //sourceHeaderDiv.append(name)
  //sourceDiv.append(sourceHeaderDiv)
  //sourceDiv.append(description)
  sourceDiv.appendTo($("#search-results"))
  
}

function searchSuccess(data, textStatus, jqXHR) {
  $('#article-results').empty();
  $('#carousel-index').empty();
  $('#carousel-content').empty();
  data.articles.forEach(addArticles);
}

function addArticles(article) {
 // var author = $("<div />", {'class' : );
  var wholeArticle = $("<div />", {'class': 'article'});
  var title = $(document.createElement('div'), {'class': 'article-title'});
  var title_content = $("<h2 class=\"post-preview\">"+ article.title + "</h2>");
  var title_by_and_time =  $("<h3 class=\"post-preview\">"+ "By: " + article.author + "-" + "Published at: " + article.publishedAt + "</h3>");
  title.append(title_content);
  title.append(title_by_and_time);
  wholeArticle.append(title);
  var content = $("<p class=\"description list-group-item-text\">"+ article.description +"</p>");
  var img = $("<img src="+ article.urlToImage + " class=\"img-fluid article-img\"" + "</img>");
  wholeArticle.append(img);
  wholeArticle.append(content);
  wholeArticle.appendTo($('#article-results'));
  
  var carouselIndex = document.getElementById('carousel-index');
  var index = carouselIndex.childElementCount;
  var nextIndex = undefined;
  if(index == 0) {
	    var newIndex = $("<li />", {'class': 'active', 'data-target':"#carousel-example-generic", 'data-slide-to':index});

  } else {
	    var newIndex = $("<li />", {'class': '', 'data-target':"#carousel-example-generic", 'data-slide-to':index});

  }
  newIndex.appendTo($('#carousel-index'));
  
  var carouselContent = document.getElementById('carousel-content');
  var item = undefined;
   if (carouselContent.childElementCount == 0) {
	    var item = $('<div />', {'class':'item active'});

  } else {
	    var item = $('<div />', {'class':'item'});

  }
  var carouselImg = $("<img src="+ article.urlToImage + " class=\"img-fluid article-img\" style=\"height: 800px; margin:auto\"" + "</img>");
  var carouselCaption = $('<div />', {'class':'carousel-caption'});
  var carousel_title_by_and_time =  $("<h4 class=\"post-preview\">"+ "By: " + article.author + "-" + "Published at: " + article.publishedAt + "</h4>");
  var carousel_title_content = $("<h3 class=\"post-preview\">"+ article.title + "</h3>");
  var carousel_content = $("<p class=\"description\">"+ article.description +"</p>");
  carouselCaption.append(carousel_title_content);
  carouselCaption.append(carousel_title_by_and_time);
  carouselCaption.append(carousel_content);
  item.append(carouselImg);
  item.append(carouselCaption);
  item.appendTo($('#carousel-content'));
}

function changeNav() {
  for(var i = 0; i < id_for_nav.length; i++) {
    var nav = document.getElementById(id_for_nav[i]);
    nav.classList.add('hidden');
  }
  for(var i = 0; i < article_source_picked.length && i < id_for_nav.length; i++) {
    var nav = document.getElementById(id_for_nav[i])
    nav.innerHTML = article_source_picked[i].name;
	nav.sourceId = article_source_picked[i].id;
    nav.classList.remove('hidden');
	nav.addEventListener('click', function(event){
		newsArticles(this.sourceId);
		for(var j = 0; j < id_for_nav.length; j++) {
			var navParent = document.getElementById(id_for_nav[j]).parentElement;
			navParent.classList.remove('active');
		}
		this.parentElement.classList.add('active');
	});
	
  }
}
function changeSource(index) {
  newsArticles(article_source_picked[index].id);

}
function refreshTags(){
	$('#choosenSource').empty();
	for(var i = 0; i < source_want_to_pick.length; i++) {
		var newTag =  $("<span class=\"badge\">" + source_want_to_pick[i].name +"</span>");
		$('#choosenSource').append(newTag);
	}
}


