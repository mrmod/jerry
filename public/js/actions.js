// Do some generic event
function do_event(e_id,e_tgt, event) {
  // console.log('Doing ' + event + ' for ' + e_id + ' @ ' + e_tgt);
  event.stop();
  $(e_id).send({
    spinner: 'spinner',
    onSuccess: function(request){  $(e_tgt).update(request.responseText);}
  });
}
// Create a form controller for our view
function make_form() {
  var frm_parts = {};
  try {
    var control_form = $('controls').find('form').map(function(e){return e.get('id');})[0];
    // console.log('Control form: ' + control_form);
    var submit_name = $(control_form).find('span').map(function(e){if(e.get('id').endsWith('submit')){return e.get('id');}})[0];
    frm_parts['form_name'] = control_form;
    frm_parts['submit_name'] = submit_name;
    // console.log('Submit: ' + submit_name);

  } catch(TypeError) {
    // console.log('No forms on this page');
  }
  return frm_parts;
}
// Handle a generic form
function handle_form(form_name, submit_name, result_tgt, mk_rmt) {
  // console.log('Creating ' + form_name + ' with submit ' + submit_name + '@ ' + result_tgt);
  try {
    if (mk_rmt == true) {
      $(form_name).remotize();
    }
  } catch (SyntaxError){
    // console.log("Not remoting the form");
  }
  $(form_name).on({submit: function(event) { do_event(form_name,result_tgt,event);}});
  $(submit_name).on({click: function(event) { do_event(form_name,result_tgt,event);}});  
}
// Delete a given node
function delete_node(e) {
  node = e.title.split('_')[1];
  new Xhr('/authorize/delete/' + node,
    { 
      onSuccess: function(r) { $('view-results').update(r.responseText);}
    }
  ).send();
}
// make a form controller for the view
try {
  frm = make_form();
  handle_form(frm['form_name'],frm['submit_name'], 'view-results');
}catch(TypeError){}

// Display the currently authorized hosts
try {
  if ($('authorize-controls').visible() ) {
    new Xhr('/authorize/nodes', 
      { method: 'get', onSuccess: function(r) { $('view-results').update(r.responseText);}}
    ).send();
  } 
} catch (TypeError) {}
