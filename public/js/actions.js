/*** Custom actions **/
Xhr.Options.spinnner = $('#spinner');
// Xhr.load('/discover/results',{spinner: 'spinner'}).update('#discovery_results');
try {
$('discover-submit').onClick(function(event) {
  // console.log("Clicked " + event.id);
  event.stop();

  $('discover-nodes').send(
    {
      spinner: 'spinner',
      onSuccess: function(request) {$('view-results').update(request.responseText);}
    }
  );
});
} catch(TypeError) {}

try {
$('inventory-submit').onClick(function(event) {
  event.stop();
  $('inventory-node').send({
    spinner: 'spinner',
    onSuccess: function(request){ $('view-results').update(request.responseText);}
  });
});
} catch (TypeError) {}


