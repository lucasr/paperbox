express = require 'express'
stylus = require 'stylus'
fs = require 'fs'

app = module.exports = express.createServer()

CATEGORIES = [
  { id: 1,  name: 'Cat 1',  order: 0 }
  { id: 2,  name: 'Cat 2',  order: 1 }
  { id: 3,  name: 'Cat 3',  order: 2 }
  { id: 4,  name: 'Cat 4',  order: 3 }
  { id: 5,  name: 'Cat 5',  order: 4 }
  { id: 6,  name: 'Cat 6',  order: 5 }
  { id: 7,  name: 'Cat 7',  order: 6 }
  { id: 8,  name: 'Cat 8',  order: 7 }
  { id: 9,  name: 'Cat 9',  order: 8 }
  { id: 10, name: 'Cat 10', order: 9 }
]

feedId = 1
entryId = 1

for c in CATEGORIES
  c.feeds = []

  for j in [1...11]
    c.feeds.push
      id: feedId
      name: "Cat #{c.id}, Feed #{feedId}"
    feedId++

  for f in c.feeds
    f.entries = []

    for i in [1...31]
      f.entries.push
        id: entryId
        title: "Entry #{entryId} (Feed #{f.id})"
        date: Math.floor(Date.now() / 1000) + i
        body: "<p>
                 Par 1 no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
               </p>
               <p>
                 Par 2 no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
               </p>
               <p>
                 Par 3 no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
                 no no no no no no no no no no no no no no no no
               </p>"
      entryId++

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'

  app.use express.logger()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session secret: 'paperbox'

  mntDir = __dirname + '/mnt'
  publicDir = __dirname + '/public'
  viewsDir = __dirname + '/views'

  # This should be moved to a Duostack deploy hook once
  # they are available to apps
  try
    fs.mkdirSync mntDir + '/stylesheets', 0755
    console.log 'Created mnt directory for stylesheets'

    fs.mkdirSync mntDir + '/js', 0755
    console.log 'Created mnt directory for javascripts'
  catch e
    console.log 'All mnt directories are already present'

  stylusArgs =
    src: viewsDir
    dest: mntDir
    compile: (str, path, fn) ->
      stylus(str)
      .set('filename', path)
      .set('compress', on)

  app.use stylus.middleware stylusArgs

  coffeeArgs =
    src: viewsDir
    dest: mntDir
    enable: ['coffeescript']

  app.use express.compiler coffeeArgs

  app.use app.router
  app.use express.static publicDir
  app.use express.static mntDir

app.configure 'development', ->
  console.log 'Using development environment'
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
  console.log 'Using production environment'
  app.use express.errorHandler()

app.get '/', (req, res) ->
  res.render 'index', title: 'PaperBox'

copyNonObjectProperties = (source, target) ->
  target[k] = v for k, v of source when typeof(v) isnt 'object'

loadCategory = (req, res, next, categoryId) ->
  # The categoryId might be undefined when using
  # the /categories with no id. Don't do anything
  # in this case.
  return next() if categoryId is undefined

  id = parseInt categoryId, 10

  found = CATEGORIES.filter (c) -> id is c.id

  if found.length isnt 1
    return next(new Error('Unable to find category'))

  req.category = {}
  copyNonObjectProperties found[0], req.category

  req.category.feeds = []
  for f in found[0].feeds
    feed = {}
    copyNonObjectProperties f, feed

    req.category.feeds.push feed

  next()

loadFeed = (req, res, next, feedId) ->
  # The feedId might be undefined when using
  # the /categories/:categoryId/feeds with no feed
  # id. Don't do anything in this case.
  return next() if feedId is undefined

  id = parseInt feedId, 10

  # Given that the feeds routes depend on categoryId
  # we should have a category set on request when we
  # reach this point.
  found = req.category.feeds.filter (f) -> id is f.id

  if found.length isnt 1
    return next(new Error('Unable to find feed'))

  req.feed = {}
  copyNonObjectProperties found[0], req.feed

  next()

loadEntry = (req, res, next, entryId) ->
  # The entryId might be undefined when using
  # the /categories/:categoryId/feeds/:feedId/entries
  # with no entry id. Don't do anything in this case.
  return next() if entryId is undefined

  id = parseInt entryId, 10

  # Given that the entries routes depend on feedId
  # we should have a feed set on request when we
  # reach this point.
  found = req.feed.entries.filter (p) -> id is p.id

  if found.length isnt 1
    return next(new Error('Unable to find entry'))

  req.entry = found[0]

  next()

app.param 'categoryId', loadCategory
app.param 'feedId', loadFeed
app.param 'entryId', loadEntry

app.get '/api/categories/:categoryId?', (req, res) ->
  if 'category' of req
    res.send req.category
  else
    res.send CATEGORIES

app.get '/api/categories/:categoryId/feeds/:feedId?', (req, res) ->
  if 'feed' of req
    res.send req.feed
  else
    res.send req.category.feeds

app.get '/api/categories/:categoryId/feeds/:feedId/entries/:entryId?', (req, res) ->
  if 'entry' of req
    res.send req.entry
  else
    res.send req.feed.entries

app.put '/api/categories/:categoryId', (req, res) ->
  req.category.name = req.body.name
  req.category.order = req.body.order

app.put '/api/categories/:categoryId/feeds/:feedId', (req, res) ->
  req.feed.name = req.body.name

app.listen(3000)
console.log "PaperBox on port %d", app.address().port
