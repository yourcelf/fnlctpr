expect     = require 'expect.js'
db         = require '../lib/db'

describe "database", ->
  it "Connects to postgres", (done) ->
    db.test (err, result) ->
      expect(err).to.be(null)
      expect(result.rows[0].test).to.eql("fiddlesticks")
      done()

  it "Creates successfully", (done) ->
    db.create (err, result) ->
      expect(err).to.be(null)
      done()

  it "Adds a record", (done) ->
    # Insert...
    db.put {q: "A"}, (err, result) ->
      expect(err).to.be(null)
      expect(result.rows[0].id).to.not.be(null)
      # Retrieve...
      db.get {q: "A"}, (err, result) ->
        expect(err).to.be(null)
        expect(result.rows[0].q).to.eql("A")
        id = result.rows[0].id
        # Retrieve another way ...
        db.get {id: id}, (err, result) ->
          expect(result.rows[0].id).to.eql(id)
          expect(result.rows[0].q).to.eql("A")
          # Retrieve another way ...
          db.list (err, result) ->
            expect(err).to.be(null)
            expect(result.rows[0].id).to.eql(id)
            # Update...
            db.put {q: "B", id: id}, (err, result) ->
              expect(result.rows[0].id).to.eql(id)
              # Remove ...
              db.remove {id: id}, (err, result) ->
                expect(err).to.be(null)
                # And it's gone!
                db.get {id: id}, (err, result) ->
                  expect(result.rows.length).to.be(0)
                  done()

