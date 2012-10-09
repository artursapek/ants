# Ants visual logger v.0.1
# Helper plugins
# Author: Artur Sapek
# MIT License

# #

# Get the float value from a percentage CSS string
parsePerc = (val) ->
  perc = parseFloat val.match(/[\d\.]+/g)
  if val.match(/..$/g)[0] == 'px'
    # Make sure we're not returning some enormous pixel amount
    # (jQuery bugs out sometimes and converts it to px)
    return 100 * (perc / document.width)
  return perc

(($) ->
  
  #  $.stretch: Helper method. Only used on the focus scrollbar's three body parts:
  #             #focus, #resize-left, #resize-right
  #             Lets user drag element to adjust percentage of any element's attribute
  $.fn.stretch = (opts) ->
    # The suspects
    $this = $(this)
    $focus = $('#focus')
    $future = $('#future')
    $left = $('#resize-left')
    $right = $('#resize-right')
    $focusfield = $('#focus-field')

    # Set up some defaults
    # We're only track x-axis movement
    lastX = undefined
    mdown = no

    # Put the mouseup and mousemove on the whole window so user can move cursor off
    # and keep dragging til they let go
    $(document).mouseup((e) ->
      mdown = no
      $focus.removeClass('hover')
      lastX = undefined
      $focusfield.hide()
    # When user is dragging:
    ).mousemove (e) ->
      if not mdown
        # If we're not dragging we don't care
        return
      
      # For collision detection later
      updateX = yes

      # How much did we move?
      changeX = e.clientX - lastX
      
      # Where are the scrollbar and future curtain?
      # Important for collision detection
      focusleft = parsePerc($focus.css 'left')
      focusright = parsePerc($focus.css 'right')
      futureleft = parsePerc($future.css 'left')

      # Percentage translation of pixel change
      perc = 100 * (changeX / $('body').width())

      # We use this plugin on three different objects,
      # and it does something a little different for each.
      id = $this.attr 'id'

      if lastX != undefined

        # For the left resize hitarea of the scrollbar
        # Stretch it to the left as far as the user likes
        # TODO: Eliminate the ability to resize the scrollbar to nonexistence
        if id == 'resize-left'
          $focus.animate
            left: '+=' + perc + '%', 0

        # For the right resize hitarea of the scrollbar
        # Stretch it to the right, as far as the "future" curtain
        else if id == 'resize-right'
          if focusright - perc > (100 - futureleft) or perc < 0
            $focus.animate
              right: '-=' + perc + '%', 0
            focus_snapped_to_now = no
          else
            $focus.animate
              right: (100 - futureleft) + '%', 0
            lastX = $future.offset().left
            updateX = no
            focus_snapped_to_now = yes
        
        # For the drag hitarea of the scrollbar (the middle 50)
        # Collision detection - don't let the user scroll into the future
        else if id == 'focus'
          offset = $focus.offset()
          if focusright - perc > (100 - futureleft) or perc < 0
            $focus.animate
              right: '-=' + perc + '%'
              left: '+=' + perc + '%'
              , 0
            focus_snapped_to_now = no
          else if Math.abs(parseInt(offset.left + $focus.width()) - parseInt($future.offset().left)) > 1
            diff = (100 - focusleft) - focusright
            $focus.animate
              right: 100 - futureleft + '%'
              left: futureleft - diff + '%'
              , 0
            lastX = e.clientX
            updateX = no
            focus_snapped_to_now = yes
          else
            focus_snapped_to_now = yes
            updateX = no

      if updateX
        # Save this x-coordinate for the next drag update
        lastX = e.clientX
        # Adjust the ants in the bottom viewport
        $('.field#bottom').find('.halo').each () ->
          $(this).reposition()

      # For visual flare, animate the blue background to help
      # show which ants are being included in the selection
      update_focus_field()

    # Start drag event when user clicks
    $this.mousedown (e) ->
      mdown = yes
      $focus.addClass('hover')
      $focusfield.show()
      e.stopPropagation()

  #  $.reposition: Helper method
  #                Positions an ant in the bottom viewport based on
  #                the scrollbar and the ant's absolute percentage value.
  #
  #  No input/output
  #
  $.fn.reposition = () ->
    $this = $(this)
    $focus = $('#focus')
    # Left edge of the scrollbar
    leftbound = parsePerc($focus.css 'left')
    # Right edge
    rightbound = 100 - parsePerc($focus.css 'right')
    # Absolute percentage of ant saved as an attribute at time of creation
    abs = parsePerc($this.attr('percentage'))
    # Relative left css value of where it should be given where the user is focusing the scrollbar
    relative = abs_to_relative([leftbound, rightbound], abs)
    $this.css
      left: relative + '%'

  #  $.popup: Helper method
  #  Constructs the hover popup for ants with their information
  #  
  #  No input/output
  $.fn.popup = () ->
    $this = $(this)
    $popup = $('<div class="popup"></div>')
    $popup.append($('<div class="timestamp">' +
                  $this.data('event') + ' - ' +
                  $this.data('timestamp') +
                  '</div><table class="data"></table>'))

    if $this.data('data') != undefined
      # Put the data up in a nice tabular layout
      $.each $this.data('data'), (i, val) ->
        $popup.find('table').append($('<tr><td>' + i + '</td><td>' + val.toString() + '</td></tr>'))
    # Event handlers for showing/hiding the popup on hover
    $this.mouseover () ->
      $popup.show()
      $this.css 'z-index', '2001'
    .mouseout () ->
      $popup.hide()
      $this.css 'z-index', '11'

    $popup.appendTo $this

)(jQuery)
