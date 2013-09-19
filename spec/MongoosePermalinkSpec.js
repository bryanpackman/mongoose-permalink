// Generated by CoffeeScript 1.3.3
var Permalink, Schema, async, dbcommon, mongoose, _ref;

Permalink = require('../lib/MongoosePermalink');

async = require('async');

dbcommon = mongoose = (_ref = require('./lib/dbcommon'), Schema = _ref.Schema, _ref);

describe("Permalink Mongoose Plugin", function() {
  /*
      mongo setup
  */

  var Foo, FooSchema, db;
  Foo = void 0;
  db = mongoose.createConnection();
  FooSchema = new Schema({
    name: String
  }).plugin(Permalink, {
    modelName: 'Foo',
    connection: db
  });
  beforeEach(function() {
    return Foo = db.fakeModel('Foo', FooSchema);
  });
  afterEach(function(done) {
    return db.tearDown(done);
  });
  describe("Base Functionality", function() {
    it("requires modelName option when applying plugin to schema", function() {
      expect(function() {
        return new Schema().plugin(Permalink);
      }).toThrow();
      return expect(function() {
        return new Schema().plugin(Permalink, {
          modelName: 'Foo'
        });
      }).not.toThrow();
    });
    it("checks if string is a valid permalink", function() {
      expect(Permalink.isValidPermalink("hi")).toBe(true);
      expect(Permalink.isValidPermalink("hi-there")).toBe(true);
      expect(Permalink.isValidPermalink("hi-there-1")).toBe(true);
      expect(Permalink.isValidPermalink("123")).toBe(true);
      expect(Permalink.isValidPermalink(Array(51).join('a'))).toBe(true);
      expect(Permalink.isValidPermalink("HI")).toBe(false);
      expect(Permalink.isValidPermalink(" hi ")).toBe(false);
      expect(Permalink.isValidPermalink("h#i")).toBe(false);
      expect(Permalink.isValidPermalink("")).toBe(false);
      expect(Permalink.isValidPermalink("-")).toBe(false);
      return expect(Permalink.isValidPermalink(Array(52).join('a'))).toBe(false);
    });
    it("gets next permalink from a base permalink", function(done) {
      var fixtures;
      spyOn(Foo, 'find').andCallFake(function(conditions, cb) {
        var docs;
        docs = (function() {
          switch (conditions.permalink.source) {
            case '^a(-\\d+)?$':
              return [];
            case '^b(-\\d+)?$':
              return [
                new Foo({
                  permalink: 'b'
                })
              ];
            case '^c(-\\d+)?$':
              return [
                new Foo({
                  permalink: 'c'
                }), new Foo({
                  permalink: 'c-1'
                })
              ];
            case '^d(-\\d+)?$':
              return [
                new Foo({
                  permalink: 'd'
                }), new Foo({
                  permalink: 'd-10'
                }), new Foo({
                  permalink: 'd-9'
                })
              ];
            case '^e-1(-\\d+)?$':
              return [];
            default:
              return null;
          }
        })();
        return cb(null, docs);
      });
      fixtures = [
        {
          base: 'a',
          expected: 'a'
        }, {
          base: 'b',
          expected: 'b-1'
        }, {
          base: 'c',
          expected: 'c-2'
        }, {
          base: 'd',
          expected: 'd-11'
        }, {
          base: 'e-1',
          expected: 'e-1'
        }
      ];
      return async.forEach(fixtures, function(e, callback) {
        return Permalink.nextPermalink(e.base, Foo, function(err, p) {
          expect(p).toBe(e.expected);
          return callback(null);
        });
      }, done());
    });
    it("returns error when attempting to save with invalid permalink", function(done) {
      var f;
      f = new Foo({
        permalink: '!!!'
      });
      return f.save(function(err, foo) {
        expect(err instanceof Permalink.PermalinkError).toBe(true);
        return done();
      });
    });
    return it("calculates a base permalink based on name field", function() {
      expect(Permalink.basePermalink("HeLLo There! ")).toBe("hello-there");
      expect(Permalink.basePermalink("  HéLLo  Th~#$êrë! ")).toBe("hello-there");
      expect(Permalink.basePermalink("HeLLo The45re! ")).toBe("hello-the45re");
      return expect(Permalink.basePermalink("Hello there", 6)).toBe("hello-");
    });
  });
  return describe("Mongo Integration", function() {
    it("converts permalink to slugified version when saving", function(done) {
      var foo;
      foo = new Foo({
        name: "Hello There"
      });
      return foo.save(function(e, f) {
        expect(f.permalink).toBe("hello-there");
        return done();
      });
    });
    it("appends numbers to already existing permalinks", function(done) {
      return async.series([
        function(callback) {
          var foo;
          foo = new Foo({
            name: "Append Test"
          });
          return foo.save(function(e, f) {
            expect(f.permalink).toBe("append-test");
            return callback(null, f);
          });
        }, function(callback) {
          var foo;
          foo = new Foo({
            name: "Append Test"
          });
          return foo.save(function(e, f) {
            expect(f.permalink).toBe("append-test-1");
            return callback(null, f);
          });
        }
      ], function(e, r) {
        return done();
      });
    });
    it("checks for uniqueness when setting permalink manually", function(done) {
      return async.series([
        function(callback) {
          var foo;
          foo = new Foo({
            name: "Unique Test"
          });
          return foo.save(function(e, f) {
            expect(f.permalink).toBe("unique-test");
            return callback(null, f);
          });
        }, function(callback) {
          var foo;
          foo = new Foo({
            name: "Unique Test Part 2",
            permalink: "unique-test"
          });
          return foo.save(function(e, f) {
            expect(f.permalink).toBe("unique-test-1");
            return callback(null, f);
          });
        }
      ], function(e, r) {
        return done();
      });
    });
    it("does not append number to unmodified permalink of already existing record", function(done) {
      return async.waterfall([
        function(callback) {
          return callback(null, new Foo({
            name: "Unmodified Test"
          }));
        }, function(foo, callback) {
          return foo.save(function(e, f) {
            expect(f.name).toBe("Unmodified Test");
            expect(f.get('__v')).toBe(0);
            expect(f.permalink).toBe("unmodified-test");
            return callback(null, f);
          });
        }, function(foo, callback) {
          foo.name = "Another Name";
          return foo.save(function(e, f) {
            expect(f.name).toBe("Another Name");
            expect(f.get('__v')).toBe(0);
            expect(f.permalink).toBe("unmodified-test");
            return callback(null, f);
          });
        }
      ], function(e, r) {
        return done();
      });
    });
    it("increments version when modifying version of existing record", function(done) {
      return async.waterfall([
        function(callback) {
          return callback(null, new Foo({
            name: "Version Test"
          }));
        }, function(foo, callback) {
          return foo.save(function(e, f) {
            expect(f.name).toBe("Version Test");
            expect(f.get('__v')).toBe(0);
            expect(f.permalink).toBe("version-test");
            return callback(null, f);
          });
        }, function(foo, callback) {
          foo.name = "Another Name";
          return foo.save(function(e, f) {
            expect(f.name).toBe("Another Name");
            expect(f.get('__v')).toBe(0);
            expect(f.permalink).toBe("version-test");
            return callback(null, f);
          });
        }, function(foo, callback) {
          foo.permalink = "version-test-a";
          return foo.save(function(e, f) {
            expect(f.name).toBe("Another Name");
            expect(f.get('__v')).toBe(1);
            expect(f.permalink).toBe("version-test-a");
            return callback(null, f);
          });
        }
      ], function(e, r) {
        return done();
      });
    });
    it("handles race conditions", function(done) {
      return async.waterfall([
        function(callback) {
          return callback(null, new Foo({
            name: "Race Test"
          }));
        }, function(foo1, callback) {
          return foo1.save(function(e, f) {
            expect(f.get('__v')).toBe(0);
            expect(f.permalink).toBe("race-test");
            return callback(null, f);
          });
        }, function(foo1, callback) {
          return Foo.findOne({
            permalink: 'race-test'
          }, function(e, f) {
            expect(f.get('__v')).toBe(0);
            expect(f.permalink).toBe("race-test");
            return callback(null, foo1, f);
          });
        }, function(foo1, foo2, callback) {
          foo1.permalink = "race-1-test";
          foo2.permalink = "race-2-test";
          return foo1.save(function(e, f) {
            expect(f.get('__v')).toBe(1);
            expect(f.permalink).toBe("race-1-test");
            return callback(null, f, foo2);
          });
        }, function(foo1, foo2, callback) {
          callback(null);
          return foo2.save(function(e, f) {
            expect(e instanceof Error).toBe(true);
            return callback(null, 'done');
          });
        }
      ], function(e, r) {
        return done();
      });
    });
    it("saves a new doc with manually set permalink", function(done) {
      var foo;
      foo = new Foo({
        name: "Manual New Permalink Test",
        permalink: "manual-npt"
      });
      return foo.save(function(e, f) {
        expect(f.name).toBe("Manual New Permalink Test");
        expect(f.permalink).toBe("manual-npt");
        expect(f.get('__v')).toBe(0);
        return done();
      });
    });
    return it("end", function(done) {
      return db.close(done);
    });
  });
});
