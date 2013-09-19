mongoose-permalink
==============

Plugin for mongoose (https://github.com/LearnBoost/mongoose) to generate and validate permalinks

## Setup
After cloning the repositiory, run `npm install` to install dependencies

## Usage

### Add Plugin To Schema
In the following example, the permalink plugin will add a String field named "permalink" to the Foo schema. When Foo objects are inserted into the database, a permalink will automatically be generated from the name field.

    var mongoose = require('mongoose')
      , db = mongoose.createConnection()
      , Schema = mongoose.Schema
      , Permalink = require('MongoosePermalink');

    var FooSchema = new Schema({ name: String }) ;
    FooSchema.plugin(
      Permalink
    , { modelName: 'Foo'
      , connection: db
      }
    ) ;

