fs = require 'fs'

try
    config = JSON.parse(fs.readFileSync(__dirname + '/../config.json', 'utf-8'))
catch e
    console.log "Skipping config file", e
    config =
        host: "localhost"
        port: 8000

module.exports = config
