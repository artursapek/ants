from django.db import models
from utils import JSON, flipstr
import datetime

class Ant(models.Model):
  def __unicode__(self):
    return '%s %s' % (self.name, self.timestamp)
  def percentage(self):
    now = datetime.datetime.now()
    d = self.timestamp
    return (float((d.hour * 3600) + (d.minute * 60) + d.second) / float(86400)) * 100
  def ajaxify(self):
    return {
      'id': self.id,
      'name': self.name,
      'percentage': self.percentage(),
      'timestamp': self.timestamp.strftime('%I:%M:%S %p'),
      'data': flipstr(self.data, '\'', '"').replace('u"', '"')
    }
  name = models.CharField(max_length=40)
  timestamp = models.DateTimeField(auto_now_add=True)
  data = models.CharField(max_length=500)

class Group(models.Model):
  def __unicode__(self):
    return '%s (%s)' % (self.name, self.ants.all().count())
  def today(self):
    now = datetime.datetime.now()
    return self.ants.filter(timestamp__year=now.year, timestamp__month=now.month, timestamp__day=now.day)
  name = models.CharField(max_length=40)
  ants = models.ManyToManyField('Ant')
