# Example of how to use ants' two main methods in your other apps

from ants.views import visual, log_event

# Set up a view to actually see the ants log in your browser
def ants_visual(request):
  # The second argument to visual is the groupname under which your events are saved.
  # This is arbitrary but must match up with your logging method, and the payload in the 
  # AJAX call in /static/ants/visual.coffee
  # You can leave this alone and everything works.
  return visual(request, 'default')

def ant(request, eventname, data={})
  # A wrapper for ants.log_event hard-coded with the group name ("default" by default)
  # and which automatically logs the user's name and email if there is a user logged in.
  # Call this in your other views to log them. Each view should use a unique name
  # (perhaps the name of the view itself).
  if not request.user.is_anonymous():
    data['user'] = '%s %s (%s)' % (request.user.first_name, request.user.last_name, request.user.email)
  log_event(request, eventname, 'default', data)

# Example urlpatterns
(r'/ants/?', 'ants.views.visual', {'group': 'default'}),
(r'/ants/update/?', 'ants.views.ajax', {'group': 'default'}),
