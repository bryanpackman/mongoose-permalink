async = require 'async'
mongoose = require 'mongoose'

exports = module.exports = mongoose

createConnection = mongoose.createConnection

mongoose.fakeModels = {}
mongoose.createConnection = ( uri = 'mongodb://localhost/PermalinkTest', options = {} ) ->

  db = createConnection.call( mongoose, uri, options );


  db.fakeModel = (name, schema, collection, skipInit) ->
    mongoose.fakeModels[name] = true
    return this.model(name, schema, collection, skipInit)

  db.tearDown = ( callback ) ->
    return callback() if db.readyState is 0
    async.forEach Object.keys( mongoose.fakeModels ), (item, done) ->
      if db.models[item]?
        db.models[item].remove {}, ( err ) ->
          delete db.models[item]
          delete mongoose.models[item]
          delete mongoose.modelSchemas[item]
          done()
      else
        done()

    , ( err ) ->
        callback()

  return db
