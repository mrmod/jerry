// Create a form controller for our view
function make_form() {
  var frm_parts = {};
  try {
    var control_form = '#' + $('form:first')[0].id;
    var submit_name = '#' + $('span[id$="-submit"]:first')[0].id;
    frm_parts['form_name'] = control_form;
    frm_parts['submit_name'] = submit_name;
    // console.log('Submit: ' + submit_name);

  } catch(TypeError) {
    // console.log('No forms on this page');
  }
  return frm_parts;
}
function huds() {
  $('input[id^="node_type"]').each(function(e){
    // $(this).nextAll().bind('click',function(e){console.log('hello');});
    $(this).parent().bind('click',function(e){
      var ph = '#'+$(this).children().first()[0].id+'ph';
      $('#search_input').attr('placeholder',$(ph).attr('value')); 
    });
  });
  // $('input[id^="node_type"]').each(function(){console.log('trigger added to ' +this.id);$(this).trigger('click');});
  Gumby.initialize('radiobtns');
  if($('form[id="authorize-node"]:visible')[0]) {
    $.ajax({
      url: '/authorize/nodes',
      method: 'GET',
      beforeSend: spinner(),
    }).done(function(data){$('#view-results').html(data);});
  }
}
// Create a spinner
function spinner(r){$(r).html('loading...');}
// Handle a generic form
function handle_form(form_name, submit_name, result_tgt) {
  var submit_action = function(e) {
    e.preventDefault();
    $.ajax({
      url: $(form_name).attr('action'),
      method: $(form_name).attr('method'),
      data: $(form_name).serialize(),
      beforeSend: spinner(result_tgt),
    }).done(function(data){$(result_tgt).empty().html(data);});
  };
  $(form_name).submit(submit_action);
  $(submit_name).click(submit_action);
}
// Delete a given node
function delete_node(e) {
  node = e.title.split('_')[1];
  $.ajax({
    url: '/authorize',
    method: 'DELETE',
    data: {'node':node},
    beforeSend: spinner(),
  }).done(function(data){
    $('#view-results').html(data);
  });
  
}
// make a form controller for the view
try {
  frm = make_form();
  handle_form(frm['form_name'],frm['submit_name'], '#view-results');
  huds();
}catch(TypeError){}