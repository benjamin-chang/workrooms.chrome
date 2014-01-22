The conference room is a lot like a controller, bringing together
multiple different elements and coordinating them. In particular, this
element is responsible for taking events from `RTCPeerConnection` objects in
scope and sending them along to the signalling server in order to set up
peer-to-peer communication.

This differs from a controller in that only the DOM scoping is used, events
bubble up from contained elements, and messages are send back down
via method calls and property sets. Nice and simple.

#Message Pattern
All calls have an outbound (you call) and an inbound (you were called) side
to match up with WebRTC's expectations.

All calls have a .id which is unique to each call, and is used
as the correlation key between the inbound and outbound side
to set up peer-peer traffic.

##Connecting State
Connecting relays through the server to find another peer to call, and
if possible, sets up a local `outboundcall`. Similarly the called side
gets a `inboundcall`.
```
  (call) -> server
  calling client <- (outboundcall | notavailable)
  called client <- (inboundcall)
```
##Connected State
When connected, calls can be modified by either side by relaying messages
though the signalling server.
**TODO** should these go peer-to-peer instead over a data channel?
```
  (mute | unmute | hangup) -> server
  any client <- (mute | unmute | hangup)
```

#Attributes
##sessionid
This is a unique random guid used to identify this running app to the
signalling server.
##signallingserver
An URL pointing to a WebSocket server used for call signalling.

#Events
##error
Bad things happen. This lets you see when.
##inboundcall
Fired when the server requests that you handle an inbound call.
##outboundcall
Fired when the server requests that you handle an outbound call.

    uuid = require('node-uuid')
    _ = require('lodash')
    qwery = require('qwery')
    bonzo = require('bonzo')
    config = require('../../config.yaml')?[chrome.runtime.id]

    Polymer 'conference-room',
      attached: ->

Hook up the session identifier and URL pointing to the appropriate signalling
server when ready. This uses the inline config object data.

        @sessionid = uuid.v1()
        @signallingserver = config.signallingServer
        @keepalive = config.keepalive or 30

This is the most important part, setting up the WebSocket to the signalling
server. Every message is built up with the `sessionid`.  WebSocket messages are
turned into DOM events or delegated to an appropriate contained call element.

* **TODO** make this an auto-reconnecting socket.  * **TODO** make this buffer
messages until the socket is available.

        socket = new WebSocket(@signallingserver)
        signalling = (message) =>
          message.sessionid = @sessionid
          socket.send(JSON.stringify(message))
        socket.onmessage = (evt) =>
          try
            message = JSON.parse(evt.data)
            if message.sdp
              console.log 'sdp', message
            if message.search and message.results
              @fire 'searchresults', message.results
            if message.inboundcall?
              @fire 'inboundcall', message
            if message.outboundcall?
              @fire 'outboundcall', message
            if message.hangup
              bonzo(qwery("ui-video-call[callid='#{message.callid}'", @shadowRoot)).remove()
          catch err
            @fire 'error', error: err

The conference room supplies the connection to the signalling server, so it
needs to listen for signal requests from contained calls and forward those
along.

        @addEventListener 'signal', (evt) =>
          signalling evt.detail

WebRTC kicks off interaction when it has something to share, namely a local
stream of data to transmit. Listen for this stream and pass it along to call
objects. This kicks off call negotiation with the signalling server.

Oh -- and -- when a local stream is available, make sure to ask if there
are any calls queued up to process!

        @addEventListener 'localstream', (evt) =>
          @localStream = evt.detail
          qwery('ui-local-video', @shadowRoot).forEach (s) =>
            s.localStream @localStream
          chrome.runtime.sendMessage
            dequeueCalls: true

Actually start up a call when requested.

        @addEventListener 'call', (evt) =>
          call = _.clone(evt.detail)
          call.callid = uuid.v1()
          signalling call

OK -- so this is the tricky bit, it isn't worth asking to connect calls until
the local stream is available.

        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          if message.call and @localStream
            chrome.runtime.sendMessage
              dequeueCalls: true
          if message.makeCalls
            message.makeCalls.forEach (call) =>
              @fire 'call', call

Set up inbound and outbound calls when asked by adding an element.

        @addEventListener 'outboundcall', (evt) ->
          bonzo(qwery('.calls', @shadowRoot))
            .append("""<ui-video-call outbound callid="#{evt.detail.callid}"></ui-video-call>""")
        @addEventListener 'inboundcall', (evt) ->
          ###
          url = evt?.detail?.userprofiles?.github?.avatar_url
          callToast = webkitNotifications.createNotification url, 'Call From', evt.detail.userprofiles.github.name
          callToast.onclick = ->
            chrome.runtime.sendMessage
              showConferenceTab: true
          callToast.show()
          ###
          bonzo(qwery('.calls', @shadowRoot))
            .append("""<ui-video-call inbound callid="#{evt.detail.callid}"></ui-video-call>""")

Keep track of OAuth supplied user profiles, and listen for them coming
in from chrome. Send them along to the signalling server. These profiles
sent to the signalling server build up a directory service dynamically. This
also acts as the keepalive for the WebSocket back to the signalling server.

        userprofiles = {}
        setInterval =>
          signalling userprofiles: @userprofiles
        , @keepalive * 1000
        @addEventListener 'userprofile', (evt) ->
          profile = evt.detail
          console.log 'profile', profile
          userprofiles[profile.profile_source] = profile
          signalling userprofiles: userprofiles
          signalling
            call: true
            callid: uuid.v1()
            to:
              gravatar: "e8f4dae176a1790b20a5f84043748675"

And call control messages for connected calls. This also heartbeats the mute
status, similar to the user profiles.

* *TODO* use peer to peer messaging for the mute controls

        muteStatus =
          sourcemutedvideo: false
          sourcemutedaudio: false
        signalMuteStatus = =>
          bonzo(qwery('ui-video-call', @shadowRoot)).each (call) ->
            signalling
              sourcemutedaudio: muteStatus.sourcemutedaudio
              sourcemutedvideo: muteStatus.sourcemutedvideo
              callid: call.callid
              peerid: call.peerid
        setInterval signalMuteStatus, @keepalive * 1000
        @addEventListener 'audio.on', (evt) ->
          muteStatus.sourcemutedaudio = false
          signalMuteStatus()
        @addEventListener 'audio.off', (evt) ->
          muteStatus.sourcemutedaudio = true
          signalMuteStatus()
        @addEventListener 'video.on', (evt) ->
          muteStatus.sourcemutedvideo = false
          signalMuteStatus()
        @addEventListener 'video.off', (evt) ->
          muteStatus.sourcemutedvideo = true
          signalMuteStatus()

Administrative actions on the tool and sidebar go here.

        @addEventListener 'sidebar', ->
          @$.sidebar.toggle()

        @addEventListener 'autocomplete', (evt) ->
          signalling search: evt.detail

        @addEventListener 'clear', (evt) =>
          @fire 'searchresults', []

        @addEventListener 'searchresults', (evt) =>
          @$.searchProfiles.model =
            profiles: evt.detail

This is just debug code.

        setTimeout =>
          @$.sidebar.toggle()

