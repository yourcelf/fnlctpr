express     = require 'express'
serialize   = require '../assets/js/serialize_pixel'
create_gif  = require './create_gif'
db          = require './db'

BASE = __dirname + '/../'

# See Cakefile for options definitions and defaults
start = (options) ->
  db.create()
  app = express.createServer()
  app.configure ->
    app.use require('connect-assets')()
    app.use express.bodyParser()
    app.use express.logger()
    app.use express.static BASE + 'assets'
    app.use '/gifs', express.static BASE + 'gifs'
    app.set 'view options', {layout: false}

  app.configure 'development', ->
    app.use express.errorHandler { dumpExceptions: true, showStack: true }

  app.set 'view engine', 'jade'

  app.post '/save', (req, res) ->
    console.log req.body
    if req.body.q
      code = serialize.normalize_pxl(req.body.q)
      db.put {q: code, id: req.body.id}, (error, results) ->
        id = results.rows[0].id
        fname = "gifs/#{id}.gif"
        path = BASE + fname
        create_gif.create_gif code, path, (err) ->
          if err?
            console.log(err)
            res.send(500, {error: "Error saving."})
          else
            res.send {'gif': "/" + fname, 'id': id, 'q': code}
    else
      res.send(404, "Query string not given.")

  app.get '/', (req, res) ->
    db.list (err, results) ->
      if err?
        console.log(err)
        res.send(500, {error: "Error fetching."})
      else
        gifs = results.rows
        for gif in gifs
          gif.gif = "/gifs/#{gif.id}.gif"
        res.render 'index', {
          title: "FnlCutPr #{req.query.id or ""}"
          gifs: gifs
        }

  app.listen options.port
  return { app }

module.exports = { start }
