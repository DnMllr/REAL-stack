let exports = exports ? window

  actionHeroWebSocket = (options, callback) ->
    if not callback? and typeof options is 'function'
      callback = options
      options = null

    @callback = {}
    @id = null
    @events = {}
    @state = 'disconnected'

    @options = @defaults!
    @options <<<< options

    if options? and options.faye?
      @faye = options.faye
    else if window.Faye?
      @faye = window.Faye
    else
      @faye = Faye

  actionHeroWebSocket.prototype.defaults = ->
    if window?
      host = window.location.origin
    {
      host: host
      path: \/faye
      setupChannel: \/_welcome
      channelPrefix: \/client/websocket/connection/
      apiPath: \/api
      connectionDelay: 500
      timeout: 60
      retry: 10
    }

  actionHeroWebSocket.prototype.log = ->
    if console? and console.log?
      unless typeof message is \string
        message = JSON.stringify it
      date = new Date!
      times =
        date.getHours!toString!
        date.getMinutes!toString!
        date.getSeconds!toString!
      times.map -> "0 #it" if it.length < 2
      console.log "[AH::client @ #{times * ''} ] #message"

  actionHeroWebSocket.prototype.connect = ->
    @startupCallback = it
    a{retry, timeout} = @options
    @client = new @faye.Client @options.host + @options.path, a
    @channel = @options.channelPrefix + @createUUID!

    @subscription = @client.subscribe @channel, -> @handleMessage it

    # @client.disable 'websocket'

    do
      <- @client.on \transport:down
      @state = \reconnecting
      if typeof @events.connect is \disconnect
        @events.disconnect \connected

    do
      <- @client.on \transport:up
      previousState = @state
      @state = \connected
      <- @setupConnection
      if previousState is \reconnecting and typeof @events.reconnect is \function
        @events.reconnect \reconnected
      else
        @events.connect \connected
        @completeConnect it

  actionHeroWebSocket.prototype.setupConnection = (callback) ->
    @messageCount = 0
    <- setTimeout _, @options.connectionDelay
    details <- @detailsView
    if @room?
      @send event: \roomChange, room: @room
    @id = details.data.id
    callback details

  actionHeroWebSocket.prototype.completeConnect = ->
    @startupCallback null, it if typeof @startupCallback is 'function'

  actionHeroWebSocket.prototype.send = (args, callback) ->
    if @state is \connected
      @messageCount++
      @callbacks[@messageCount] = callback if typeof callback is \function
      @client.publish @channel, args .errback (err) -> @log err
    else if typeof callback is \function
      callback error: "not connected", state: @state

  actionHeroWebSocket.prototype.handleMessage = (message) ->
    switch message.context 
    | \response
      @callbacks[message.messageCount] message if typeof @callbacks[message.messageCount] is \function
      delete @callbacks[message.messageCount]
    | \user => @events.say message if typeof @events.say is \function
    | \alert => @events.api message if typeof @events.api is \function
    | \api
      if message.welcome?
        @welcomeMessage = message.welcome
        @events.welcome message if typeof @events.say is \function and typeof @events.welcome is \function
      else
        @events.api message if typeof @events.api is \function

  actionHeroWebSocket.prototype.createUUID = ->
    hexDigits = \0123456789abcdef
    s = [hexDigits.substr (Math.floor Math.random! * 0x10), 1 for x in [0 to 36]]
    s[14] = "4" # bits 12-15 of the time_hi_and_version field to 0010
    s[19] = hexDigits.substr s[19] .&. 0x3 .|. 0x8, 1 # bits 6-7 of the clock_seq_hi_and_reserved to 01
    s[8] = s[13] = s[18] = s[23] = \-
    s * ''

  actionHeroWebSocket.prototype.action = (action, params, callback) ->
    if callback? and typeof params is \function
      callback = params
      params = null
    params = params ? {}
    params.action = action
    @send event: 'action', params: params, callback

  actionHeroWebSocket.prototype.say = (message, callback) ->
    @send event: \say, message: message, callback

  actionHeroWebSocket.prototype.detailsView = -> @send event: \detailsView, it

  actionHeroWebSocket.prototype.roomView = -> @send event: \roomView, it

  actionHeroWebSocket.prototype.roomChange = (room, callback) ->
    @room = room
    @send event: \roomChange, room: room, callback

  actionHeroWebSocket.prototype.listenToRoom = (room, callback) -> @send event: \listenToRoom, room: room, callback

  actionHeroWebSocket.prototype.silenceRoom = (room, callback) -> @send event: \silenceRoom, room: room, callback

  actionHeroWebSocket.prototype.documentation = -> @send event: \documentation, it

  actionHeroWebSocket.prototype.disconnect = ->
    @state = \disconnected
    @client.disconnect!

  exports.actionHeroWebSocket = actionHeroWebSocket