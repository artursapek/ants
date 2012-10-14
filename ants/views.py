from django.http import HttpResponse
from django.shortcuts import render_to_response as render
from django.utils import simplejson
from utils import JSON
from ants.models import Ant, Group

def visual(request, group):
  try:
    gr = Group.objects.get(name=group)
  except:
    # If the timeline is visited before any events have been logged, make a blank new group
    gr = Group(name=group)
    gr.save()

  events = gr.today()

  # Figure out how many different events there are total
  allevents = gr.ants.all()
  alleys = {}

  for event in allevents:
    alleys[event.name] = 0

  namescount = len(alleys.keys())

  alleyheight = 100 / (namescount + 1)

  # Predetermine the spacing between the alleys
  # based on how many there will be
  for i, event in enumerate(alleys):
    alleys[event] = alleyheight * (i + 1)

  return render('visual.html', { 'alleys': alleys })

def log_event(request, name, group, addtldata=None):
  event = Ant(name=name)
  # Save the user-agent for each event by default
  data = { 'ua': request.META['HTTP_USER_AGENT'] }

  # Merge in the additional data if it was provided
  if addtldata:
    for key in addtldata:
      data[key] = addtldata[key]

  event.data = data
  event.save()

  # Try saving the ant to its specified group
  try:
    gr = Group.objects.get(name=group)
    gr.ants.add(event)
    gr.save()
  # If the group doesn't exist, create it for the first time
  except:
    gr = Group(name=group)
    gr.save()
    gr.ants.add(event)
    gr.save()

  return HttpResponse(status=200)

def ajax(group):
  gr = Group.objects.get(name=group)
  data = {}
  for event in gr.today():
    data[event.id] = event.ajaxify()
  return JSON(data)

def JSON(obj):
    return HttpResponse(simplejson.dumps(obj, separators=(',',':')), mimetype='application/javascript')
