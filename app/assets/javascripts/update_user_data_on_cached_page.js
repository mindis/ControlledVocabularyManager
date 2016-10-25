// When rendering a cached page, this ajax call will 'refresh' the navbar to be relative to the
// current_user if there is one logged in, and display admin specific buttons
$(document).ready(function(){
  $.ajax({ url: "/nav" })
    .done(function(html) {
      $('nav.navbar').remove();
      $('body').prepend(html);
    });
  $.ajax({ url: "/is_admin" })
    .done(function(json) {
      if(json.admin) {
        $(".hidden-unless-admin").show();
      }
    });
});
