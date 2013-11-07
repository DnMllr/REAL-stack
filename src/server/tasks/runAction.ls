task = {}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# metadata

task.name = 'runAction'
task.description = 'I will run an action and return the connection object'
task.scope = 'any'
task.frequency = 0

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# functional

task.run = (api, params = {}, next) ->
  connection = new api.connection do
    type: \task
    remotePort: \0
    remoteIP: \0
    rawConnection: {}

  connection.params = params # params.action should be set

  actionProcessor = new api.actionProcessor do
    connection: connection
    callback: (connection, cont) ->
      if connection.error?
        api.log "task error #{connection.error}", "error", params: JSON.stringify params
      else 
        api.log "[ action @ task ]", "debug", params: JSON.stringify params
      <- connection.destroy
      next connection, true

  actionProcessor.processAction!


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# exports

exports.task = task