// From https://github.com/ariya/phantomjs/issues/10389

var page;
var timer;

var system = require('system');
var myurl = system.args[1];

var renderPage = function (url) {
    url = url.trim();
    page = require('webpage').create();

    clearTimeout(timer)
    timer = setTimeout(function() { endProcess(); }, 10000);

    page.onNavigationRequested = function(url, type, willNavigate, main) {
        if (main && url!=myurl) {
            myurl = url;
            page.close()

            //setTimeout('renderPage(myurl)',1); // recurse
            setTimeout(function() { renderPage(myurl); }, 1 ) // recurse
            console.log(url)
        }
    };

    page.open(url, function(status) {
        if (status==='success') {
            phantom.exit(0);
        } else {
            phantom.exit(1);
        }
    });
} 

function endProcess() {
  return false;
}

renderPage(myurl);