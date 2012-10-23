fs = require 'fs'

try
    config = JSON.parse(fs.readFileSync(__dirname + '/../config.json', 'utf-8'))
catch e
    console.log "WARNING: Skipping config file", e
    console.log "Database will not be available."
    config =
        host: "localhost"
        port: 8000

module.exports = config
