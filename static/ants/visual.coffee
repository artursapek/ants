# Ants visual logger v.0.1
# Main code
# Author: Artur Sapek
# MIT License

# #

# This keeps track of whether the scrollbar is stuck to the present,
# meaning it will move as time goes on and the ants in the bottom viewport
# will be moving through it.
focus_snapped_to_now = yes

# getdata : Helper method. Makes ajax call to update the ants data
# Called by: update
getdata = () ->
  $.ajax
    type: 'GET'
    url: '/ants/update'
    dataType: 'json'
    success: (data) ->
      for id, ant of data
        # If we haven't yet, create the ant
        if $('#' + id).length == 0

          # The proper alley to append the ant to
          $alley = $('.alley#' + ant.name)

          # Make our first ant, which will go in the day view at the top
          $ant = $('<div class="halo"><div class="ant"></div></div>').attr(
            id: id
            percentage: ant.percentage
          ).css(
            left: "#{ant.percentage}%"
            top: $alley.css('top')
          )
          # Make another to put in the bottom viewport
          $bottomclone = $ant.clone()

          # For some reason cloning an element doesn't clone its data :(
          $.each([$ant, $bottomclone], ->
            this.data('data', JSON.parse(ant.data))
            this.data('timestamp', ant.timestamp)
            this.data('event', ant.name)
            # Use custom plugin to build the information popup
            this.popup())

          $('.field#day').append($ant)
          $('.field#bottom').append($bottomclone)
          
          # Use custom plugin to reposition the clone relative to the time
          $bottomclone.reposition()

#  abs_to_relative : Helper method. Does the math for positioning the ants in the bottom viewport.
#  Called by: update
#
#  I/P: range: array [min (float), max (float)]
#              Relative min and max percentages on the day scale. Derived from the scrollbar
#
#       abs:   float
#              Ant's event percentage on the day scale. Derived from 'left' css attr
#
#  O/P:        float
#              Ant's relative percentage on the relative scale for inside the bottom viewport
#
abs_to_relative = (range, abs) ->
  100 * ((abs - range[0]) / (range[1] - range[0]))

#  update_focus_field : Helper method. Makes the blue background move
#                       with the focus scrollbar when it gets dragged around.
#
#  No input/output
#
update_focus_field = ->
  $focus = $('#focus')
  $('#focus-field').css
    left: $focus.css 'left'
    right: $focus.css 'right'

#  update : Main method. Called every five seconds to make everything tick.
#  Called by: interval set in $doc.ready
#
#  No input/output
#
update = () ->
  $focus = $('#focus')

  # Get the exact current percentage of time we've gone through the day.
  now = new Date()
  percentage = (((now.getHours() * 3600) + (now.getMinutes() * 60) + now.getSeconds()) / 86400) * 100

  # Update the future screen's position/size, making it "reveal" the log
  $('#future').css
    left: percentage + '%'

  # The vertical markers indicating noon and 6 hours before and after
  landmarks = { 25: '#6am', 50: '#noon', 75: '#6pm' }

  # Show them as we come to that time of day 
  # Otherwise leave them hidden behind the "future"
  for perc in Object.keys(landmarks)
    if percentage > perc
      $(landmarks[perc]).show()

  # Reposition each ant in the bottom viewport with the update time percentage
  $('.field#bottom .halo').each () ->
    $(this).reposition()
 
  # If the scrollbar is all the way to the right and we're having it move with time, update its position.
  if focus_snapped_to_now
    focus_width = (100 - parsePerc($focus.css 'right')) - parsePerc($focus.css 'left')
    $focus.css
      left: percentage - focus_width + '%'
      # Subtract 100 to measure relative to the right
      right: 100 - percentage + '%'
    # Since we've changed the relative viewport by moving the scrollbar, update all the ants in the viewport
    # (this is where the ants shift a tiny bit every five seconds)
    update_focus_field()

  # Call server for new ants
  getdata()

# Finally, let's bind everything to an interval and set up the scrollbar
$(document).ready ->
  # Run update once initially
  update()

  # Set an interval to do it every 5 seconds
  # Change this value to in/decrease the responsiveness of your Ants logger
  setInterval update, 5000

  # Use another custom plugin to give the focus scrollbar its draggability
  $('#focus, #resize-left, #resize-right').each ->
    $(this).stretch()
