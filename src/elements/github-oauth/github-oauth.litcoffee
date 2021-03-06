Sign in via GitHub. This will trigger an OAuth user authentication by
its mere presence, and then expose the user profile.

#Attributes
##clientid
OAuth client id string
##clientsecret
OAuth client secret string
##userProfile
Becomes available after an authentication.

#Events
##userprofile
When the user profile is available from GitHub post OAuth.
##error
When bad things happen.

#Methods
##login
Call this to force the login sequence.

    github = require('./github-auth.js')
    _ = require('lodash')

    Polymer 'github-oauth',
      inProgress: false
      attached: ->
        document.addEventListener 'getuserprofile', =>
          if @userProfile
            @fire 'userprofile', @userProfile
          else
            @login()

This will sign you in to github as soon as it comes in the DOM.

      attributeChanged: (name, oldvalue, newvalue) ->
        if not @clientid.match(/{{/) and not @clientsecret.match(/{{/)
          @login()

Little debounce to avoid double login as the `clientid` and `clientsecret`
are set typically in sequence.

      login: ->
        if @inProgress
          return
        else
          @inProgress = true
          github.login @getAttribute('clientid'), @getAttribute('clientsecret'), (error, info) =>
            if error
              @inProgress = false
              @fire 'error', error
            else
              @inProgress = false
              info.profile_source = 'github'
              @userProfile = info
              @fire 'userprofile', info
