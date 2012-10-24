pg = require("pg")
config = require "./config"

test = (fn) ->
  pg.connect config.pg_connection, (err, client) ->
    fn(err) if err
    client.query("SELECT 'fiddlesticks' AS test", fn)

create = (fn) ->
  pg.connect config.pg_connection, (err, client) ->
    fn(err) if err
    client.query(
      "CREATE TABLE IF NOT EXISTS fnlctpr ( id SERIAL, q VARCHAR(2000) )",
      fn
    )

get = (query, fn) ->
  pg.connect config.pg_connection, (err, client) ->
    fn(err) if err
    if query.id?
      client.query("SELECT id,q FROM fnlctpr WHERE id = $1", [query.id], fn)
    else if query.q
      client.query("SELECT id,q FROM fnlctpr WHERE q = $1", [query.q], fn)

put = (query, fn) ->
  pg.connect config.pg_connection, (err, client) ->
    fn(err) if err
    if query.id?
      client.query("UPDATE fnlctpr SET q = $1 WHERE id = $2 RETURNING id", [query.q, query.id], fn)
    else
      client.query('INSERT INTO fnlctpr (q) VALUES ($1) RETURNING id', [query.q], fn)

remove = (query, fn) ->
  pg.connect config.pg_connection, (err, client) ->
    fn(err) if err
    if query.id?
      client.query("DELETE FROM fnlctpr WHERE id = $1", [query.id], fn)
    else
      fn("Error: query.id must be specified.")

list = (fn) ->
  pg.connect config.pg_connection, (err, client) ->
    fn(err) if err
    client.query("SELECT id,q FROM fnlctpr ORDER BY id DESC", fn)

module.exports = { create, get, put, remove, list, test }
