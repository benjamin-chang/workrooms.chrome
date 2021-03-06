A simple toggle button with a FontAwesome icon. Fires off an event indicating
the toggled state.

#Attributes
##togglechanged
This is the name of an event to fire when the toggle has changed.
##active
When present, the toggle is on.
##icon
Name of a the font-awesome style to use as the icon. If you really want
you can put any style names in here to use other than FontAwesome.

#Events
This fires a dynamic event based on `togglechanged`. Will fire a
`.on` and a `.off` suffixed event depending on the state.

    Polymer 'ui-toggle-tool',
      attached: ->
        @addEventListener 'click', ->
          if @hasAttribute('active')
            @removeAttribute('active')
          else
            @setAttribute('active', '')
      activeChanged: (oldValue, newValue) ->
        if newValue?
          @fire "#{@togglechanged}.on"
          @$.tool.classList.add('active')
        else
          @fire "#{@togglechanged}.off"
          @$.tool.classList.remove('active')

