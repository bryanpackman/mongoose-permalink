// Generated by CoffeeScript 1.3.3
var async, createConnection, exports, mongoose;

async = require('async');

mongoose = require('mongoose');

exports = module.exports = mongoose;

createConnection = mongoose.createConnection;

mongoose.fakeModels = {};

mongoose.createConnection = function(uri, options) {
  var db;
  if (uri == null) {
    uri = 'mongodb://localhost/PermalinkTest';
  }
  if (options == null) {
    options = {};
  }
  db = createConnection.call(mongoose, uri, options);
  db.fakeModel = function(name, schema, collection, skipInit) {
    mongoose.fakeModels[name] = true;
    return this.model(name, schema, collection, skipInit);
  };
  db.tearDown = function(callback) {
    if (db.readyState === 0) {
      return callback();
    }
    return async.forEach(Object.keys(mongoose.fakeModels), function(item, done) {
      if (db.models[item] != null) {
        return db.models[item].remove({}, function(err) {
          delete db.models[item];
          delete mongoose.models[item];
          delete mongoose.modelSchemas[item];
          return done();
        });
      } else {
        return done();
      }
    }, function(err) {
      return callback();
    });
  };
  return db;
};
