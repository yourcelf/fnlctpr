express     = require 'express'
fs          = require 'fs'
serialize   = require '../assets/js/serialize_pixel'
create_gif  = require './create_gif'
db          = require './db'

# See Cakefile for options definitions and defaults
start = (options) ->
  db.create()
  app = express.createServer()
  app.configure ->
    app.use require('connect-assets')()
    app.use express.logger()
    app.use express.static __dirname + '/../assets'
    app.use express.static __dirname + 'gifs'
    app.set 'view options', {layout: false}

  app.configure 'development', ->
    app.use express.errorHandler { dumpExceptions: true, showStack: true }

  app.set 'view engine', 'jade'

  app.post '/save', (req, res) ->
  app.get '/', (req, res) ->

  app.get /([-0-9A-Za-z_~]+)\.gif/, (req, res) ->
    code = serialize.normalize_pxl(req.params[0])
    path = "gifs/#{code}.gif"
    send = -> res.sendfile(path)
    fs.exists path, (exists) ->
      if not exists
        create_gif.create_gif(code, path, send)
      else
        send()

  app.get '/', (req, res) ->
    res.render 'index', title: "FnlCutPr", slug: ""

  app.get /([-0-9A-Za-z_~]+)/, (req, res) ->
    res.render 'index', title: req.params[0], slug: req.params[0]

  app.listen options.port
  return { app }

module.exports = { start }
