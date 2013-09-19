mongoose-permalink
==============

Plugin for mongoose (https://github.com/LearnBoost/mongoose) to generate and validate permalinks

## Setup
After cloning the repositiory, run `npm install` to install dependencies

## Usage
For more details on using a mongoose plugins, check the [plugins section](http://mongoosejs.com/docs/plugins.html) of the mongoose documentation

### Add Plugin To Schema
In the following example, the permalink plugin will add a String field named "permalink" to the Foo schema. When Foo objects are inserted into the database, a permalink will automatically be generated from the name field.

    var mongoose = require('mongoose')
      , Schema = mongoose.Schema
      , Permalink = require('./lib/MongoosePermalink');
    mongoose.connect('localhost', 'gettingstarted');
    
    var FooSchema = new Schema({ name: String }) ;
    FooSchema.plugin(Permalink, { modelName: 'Foo' });
    
### Insert Records
Using the above schema with an empty collection:

    var Foo = mongoose.model('Foo', FooSchema);
    var firstFoo = new Foo({ name: 'foo' }), secondFoo = new Foo({ name: "foo" });
    
    firstFoo.save(function (err) {
      if (err) {
        console.log("e1", err);
        return;
      } else {
        secondFoo.save(function (err) {
          if (err) {
            console.log(err);
            return;
          } else {
            console.log(firstFoo, secondFoo);
            //saved! entries are:
            // { __v: 0, permalink: 'foo', name: 'foo', _id: 523b5ea6e36507813f000001 } 
            // { __v: 0, permalink: 'foo-1', name: 'foo', _id: 523b5ea6e36507813f000002 }
          }
        } );
      }
    });

### Configuration

#### modelName (required)
Name of model this schema applies to. This is needed to call <modelName>.find when checking if the generated permalink already exists in our collection. If it exists, a number will be appended to keep the peramlink value unique.

#### connection 
Database connection. Defaults to `mongoose`

#### target 
Name of field where permalink value is stored. Defaults to "permalink".

#### source
Name of field where permalink value is generated from. Defaults to "name".

#### maxLength
Maximum length of permalink value in bytes. Defaults to 50
