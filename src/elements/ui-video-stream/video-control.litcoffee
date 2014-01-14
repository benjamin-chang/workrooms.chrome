This is a non visual element that listens for
`audio.on` and `audio.off` and `stream` events and then mutes
or unmutes said stream for you.

Not clear that this really warrants being its own component.

    Polymer 'audio-control',
      attached: ->
        @addEventListener 'stream', (evt) =>
          @stream = evt.detail.stream
        @addEventListener 'video.on', (evt) =>
          @stream?.getVideoTracks()?.forEach (x) -> x.enabled = true
        @addEventListener 'video.off', (evt) =>
          @stream?.getVideoTracks()?.forEach (x) -> x.enabled = false
