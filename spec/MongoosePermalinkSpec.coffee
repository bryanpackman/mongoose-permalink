Permalink = require '../lib/MongoosePermalink'
async = require 'async'
dbcommon = mongoose = { Schema } = require( './lib/dbcommon' )

describe "Permalink Mongoose Plugin", ->

  ###
    mongo setup
  ###
  Foo = undefined
  db = mongoose.createConnection()
  FooSchema = new Schema( name: String ).plugin Permalink, modelName : 'Foo', connection: db

  beforeEach ->
    Foo = db.fakeModel 'Foo', FooSchema

  afterEach (done) ->
    db.tearDown done

  describe "Base Functionality", ->
    it "requires modelName option when applying plugin to schema", ->
      expect( -> new Schema().plugin Permalink).toThrow()
      expect( -> new Schema().plugin Permalink, modelName : 'Foo').not.toThrow()

    it "checks if string is a valid permalink", ->
      expect( Permalink.isValidPermalink( "hi" ) ).toBe true
      expect( Permalink.isValidPermalink( "hi-there" ) ).toBe true
      expect( Permalink.isValidPermalink( "hi-there-1" ) ).toBe true
      expect( Permalink.isValidPermalink( "123" ) ).toBe true
      expect( Permalink.isValidPermalink( Array(51).join('a') ) ).toBe true
      expect( Permalink.isValidPermalink( "HI" ) ).toBe false
      expect( Permalink.isValidPermalink( " hi " ) ).toBe false
      expect( Permalink.isValidPermalink( "h#i" ) ).toBe false
      expect( Permalink.isValidPermalink( "" ) ).toBe false
      expect( Permalink.isValidPermalink( "-" ) ).toBe false
      expect( Permalink.isValidPermalink( Array(52).join('a') ) ).toBe false

    it "gets next permalink from a base permalink", (done) ->
      spyOn(Foo, 'find').andCallFake (conditions, cb) ->

        docs = switch conditions.permalink.source
          when '^a(-\\d+)?$' then []
          when '^b(-\\d+)?$' then [new Foo(permalink:'b')]
          when '^c(-\\d+)?$' then [new Foo(permalink:'c'), new Foo(permalink:'c-1')]
          when '^d(-\\d+)?$' then [new Foo(permalink:'d'), new Foo(permalink:'d-10'), new Foo(permalink:'d-9')]
          when '^e-1(-\\d+)?$' then []
          else null
        cb null, docs

      fixtures =
      [ { base : 'a', expected : 'a' }
      , { base : 'b', expected : 'b-1' }
      , { base : 'c', expected : 'c-2' }
      , { base : 'd', expected : 'd-11' }
      , { base : 'e-1', expected : 'e-1' }
      ]

      async.forEach fixtures, (e, callback) ->
        Permalink.nextPermalink e.base, Foo, (err, p) ->
          expect(p).toBe e.expected
          callback(null)
      , done()

    it "returns error when attempting to save with invalid permalink", (done) ->
      f = new Foo permalink:'!!!'
      f.save (err, foo) ->
        expect(err instanceof Permalink.PermalinkError).toBe true
        done();


    it "calculates a base permalink based on name field", ->
      expect( Permalink.basePermalink "HeLLo There! ").toBe "hello-there"
      expect( Permalink.basePermalink "  HéLLo  Th~#$êrë! ").toBe "hello-there"
      expect( Permalink.basePermalink "HeLLo The45re! ").toBe "hello-the45re"
      expect( Permalink.basePermalink "Hello there", 6).toBe "hello-"

  describe "Mongo Integration", ->

    it "converts permalink to slugified version when saving", (done) ->
      foo = new Foo name: "Hello There"
      foo.save (e, f) ->
        expect( f.permalink ).toBe "hello-there"
        done()

    it "appends numbers to already existing permalinks", (done) ->
      async.series [
        (callback) ->
          foo = new Foo name: "Append Test"
          foo.save (e, f) ->
            expect( f.permalink ).toBe "append-test"
            callback(null, f)
      , (callback) ->
          foo = new Foo name: "Append Test"
          foo.save (e, f) ->
            expect( f.permalink ).toBe "append-test-1"
            callback(null, f)
      ]
      , (e, r) ->
          done()

    it "checks for uniqueness when setting permalink manually", (done) ->
      async.series [
        (callback) ->
          foo = new Foo name: "Unique Test"
          foo.save (e, f) ->
            expect( f.permalink ).toBe "unique-test"
            callback(null, f)
      , (callback) ->
          foo = new Foo name: "Unique Test Part 2", permalink: "unique-test"
          foo.save (e, f) ->
            expect( f.permalink ).toBe "unique-test-1"
            callback(null, f)
      ]
      , (e, r) ->
          done()

    it "does not append number to unmodified permalink of already existing record", (done) ->

      async.waterfall [
        (callback) -> callback(null, new Foo name: "Unmodified Test")
        (foo, callback) ->
          foo.save (e, f) ->
            expect( f.name ).toBe "Unmodified Test"
            expect( f.get('__v')).toBe 0
            expect( f.permalink ).toBe "unmodified-test"
            callback(null, f)
      , (foo, callback) ->
          foo.name = "Another Name"
          foo.save (e, f) ->
            expect( f.name ).toBe "Another Name"
            expect( f.get('__v')).toBe 0
            expect( f.permalink ).toBe "unmodified-test"
            callback(null, f)
      ]
      , (e, r) ->
          done()

    it "increments version when modifying version of existing record", (done) ->
      async.waterfall [
        (callback) -> callback(null, new Foo name: "Version Test")
        (foo, callback) ->
          foo.save (e, f) ->
            expect( f.name ).toBe "Version Test"
            expect( f.get('__v')).toBe 0
            expect( f.permalink ).toBe "version-test"
            callback(null, f)
      , (foo, callback) ->
          foo.name = "Another Name"
          foo.save (e, f) ->
            expect( f.name ).toBe "Another Name"
            expect( f.get('__v')).toBe 0
            expect( f.permalink ).toBe "version-test"
            callback(null, f)
      , (foo, callback) ->
          foo.permalink = "version-test-a"
          foo.save (e, f) ->
            expect( f.name ).toBe "Another Name"
            expect( f.get('__v')).toBe 1
            expect( f.permalink ).toBe "version-test-a"
            callback(null, f)
      ]
      , (e, r) ->
          done()


    it "handles race conditions", (done) ->
      async.waterfall [
        (callback) ->
          callback(null, new Foo name: "Race Test")
        (foo1, callback) ->
          foo1.save (e, f) ->
            expect( f.get('__v')).toBe 0
            expect( f.permalink ).toBe "race-test"
            callback(null, f)
      , (foo1, callback) ->
          Foo.findOne permalink:'race-test', (e, f) ->
            expect( f.get('__v')).toBe 0
            expect( f.permalink ).toBe "race-test"
            callback(null, foo1, f)
      , (foo1, foo2, callback) ->
          foo1.permalink = "race-1-test"
          foo2.permalink = "race-2-test"
          foo1.save (e, f) ->
            expect( f.get('__v')).toBe 1
            expect( f.permalink ).toBe "race-1-test"
            callback(null, f, foo2)
      , (foo1, foo2, callback) ->
          callback(null)
          foo2.save (e, f) ->
            expect(e instanceof Error).toBe true
            callback(null, 'done')
      ]
      , (e, r) ->
          done()

    it "saves a new doc with manually set permalink", (done) ->
      foo = new Foo
        name: "Manual New Permalink Test"
        permalink: "manual-npt"

      foo.save (e, f) ->
        expect( f.name).toBe "Manual New Permalink Test"
        expect( f.permalink).toBe "manual-npt"
        expect( f.get('__v')).toBe 0
        done()

    it "end", (done) ->
      db.close done

