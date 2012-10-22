config  = require './lib/config'

# You can override the configured defaults for port and host with flags.
option '-p', "--port [#{config.port}]", 'port the server runs on'
option '-h', "--host [#{config.host}]", 'base server name'

task 'runserver', 'Run the server.', (options) ->
  server = require './lib/server'
  server.start
    host: options.host or config.host
    port: options.port or config.port
