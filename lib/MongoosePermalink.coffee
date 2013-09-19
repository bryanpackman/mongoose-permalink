mongoose = require 'mongoose'

fr = 'àáâãäåçèéêëìíîïñðóòôõöøùúûüýÿ'      # Accent chars to find
to = 'aaaaaaceeeeiiiinooooooouuuuyy'      # Accent replacement

module.exports = exports = (schema, options) ->


  modelName = options.modelName
  connection = options.connection or mongoose

  target = options.target or 'permalink'         # Slug destination
  source = options.source or 'name'         # Slug content field
  maxLength = options.maxLength or 50       # Max slug length

  fields = {}
  fields[target] = String

  schema.add fields
  schema.pre 'save', (next) ->
    if this[target]? and not @isNew and not @isModified(target)
      next()
    else
      basePermalink = this[target] or getBasePermalink(this[source], maxLength)
      self = this
      getNextPermalink(basePermalink, connection.model(modelName), (err, nextP) ->
        if err then next(err)
        else
          self[target] = nextP
          if not self.isNew then self.increment()
          next()
      , target)


exports.basePermalink = getBasePermalink = (name, maxLength = 50) ->

  #if (!str) return
  name = name
    .replace(/^\s+|\s+$/g, '')
    .toLowerCase()

  # Convert all accent characters
  for char, i in fr.split ''
    do (i, char) ->
      name = name.replace(new RegExp(char, 'g'), to.charAt(i))

  # Replace all invalid characters and spaces, truncating to the max length
  return name
    .replace(/[^a-z0-9 -]/g, '')
    .replace(/\s+/g, '-')
    .substr(0, maxLength)

exports.nextPermalink = getNextPermalink = (basePermalink, model, cb, permalinkField = 'permalink') ->
  if not isValidPermalink basePermalink
    cb new PermalinkError("Invalid Permalink"), null
  else
    conditions = {}
    conditions[permalinkField] = new RegExp('^' + basePermalink + '(-\\d+)?$')
    model.find conditions, (e,r) ->
      if e?
        cb(e, null)
      else

        nextPermalink = basePermalink
        max = 0
        permRegExp = new RegExp('^' + basePermalink + '-(\\d+)$')
        for item in r
          if (item.permalink is basePermalink and max is 0) #then do (item) ->
            nextPermalink  = basePermalink + '-1'
          else
            version = parseInt permRegExp.exec(item.permalink)[1]
            if version > max
              nextPermalink = basePermalink + '-' + ( version + 1 )
              max = version
        cb(null, nextPermalink)

exports.isValidPermalink = isValidPermalink = (str, maxLength = 50) ->
  str.length > 0 and
  str.length <= maxLength and
  str isnt '-' and
  not /[^a-z0-9-]/g.test(str)

class PermalinkError extends Error
  constructor: (@message = "Permalink Error") ->
  name: "PermalinkError"

exports.PermalinkError = PermalinkError

