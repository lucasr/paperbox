express = require 'express'
stylus = require 'stylus'
fs = require 'fs'

app = module.exports = express.createServer()

N_CATEGORIES = 10
N_FEEDS = 10
N_ENTRIES = 30

CATEGORIES = {}
FEEDS = {}
ENTRIES = {}

categoryId = feedId = entryId = 1

for c in [0...N_CATEGORIES]
  category =
    id: categoryId
    name: "Cat #{categoryId}"
    order: c
    feeds: []

  CATEGORIES[category.id] = category

  categoryId++

  for f in [0...N_FEEDS]
    feed =
      id: feedId
      name: "Feed #{feedId} (Cat #{category.id})"
      entries: []
      categoryId: category.id

    FEEDS[feed.id] = feed
    category.feeds.push feed

    feedId++

    for e in [0...N_ENTRIES]
      entry =
        id: entryId
        title: "Entry #{entryId} (Feed #{feed.id})"
        date: Date.now() - (86400000 * e)
        body: ""
        feed: feed.name

      nParagraphs = Math.floor(Math.random() * 4) + 1
      for p in [1..nParagraphs]
        entry.body += '<p>'

        nWords = Math.floor(Math.random() * 76) + 20
        entry.body += 'no ' for w in [0..nWords]

        entry.body += '</p>'

      ENTRIES[entry.id] = entry
      feed.entries.push entry

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

loadCategory = (categoryId) ->
  category = {}
  copyNonObjectProperties CATEGORIES[categoryId], category

  category.feeds = []
  for f in CATEGORIES[categoryId].feeds
    feed = {}

    copyNonObjectProperties f, feed
    category.feeds.push feed

  category

handleCategoryId = (req, res, next, categoryId) ->
  id = parseInt categoryId, 10

  if not CATEGORIES[id]?
    return next(new Error('Unable to find category'))

  req.category = loadCategory id

  next()

loadFeed = (feedId) ->
  feed = {}

  console.log 'Loading feed ' + FEEDS[feedId].name
  copyNonObjectProperties FEEDS[feedId], feed

  feed

handleFeedId = (req, res, next, feedId) ->
  id = parseInt feedId, 10

  if not FEEDS[id]?
    return next(new Error('Unable to find feed'))

  req.feed = loadFeed id

  next()

handleEntryId = (req, res, next, entryId) ->
  id = parseInt entryId, 10

  if not ENTRIES[id]?
    return next(new Error('Unable to find entry'))

  req.entry = ENTRIES[id]

  next()

app.param 'categoryId', handleCategoryId
app.param 'feedId', handleFeedId
app.param 'entryId', handleEntryId

# Categories

app.get '/api/categories', (req, res) ->
  categories = []

  for id, c of CATEGORIES
    categories.push loadCategory id

  res.send categories

app.get '/api/category/:categoryId', (req, res) ->
  res.send req.category

app.put '/api/category/:categoryId', (req, res) ->
  CATEGORIES[req.category.id].name = req.body.name
  CATEGORIES[req.category.id].order = req.body.order

app.get '/api/category/:categoryId/feeds', (req, res) ->
  res.send req.category.feeds

# Feeds

app.get '/api/feed/:feedId', (req, res) ->
  res.send req.feed

app.put '/api/feed/:feedId', (req, res) ->
  FEEDS[req.feed.id].name = req.body.name

app.get '/api/feed/:feedId/entries', (req, res) ->
  res.send FEEDS[req.feed.id].entries

# Entries

app.get '/api/entry/:entryId', (req, res) ->
  res.send req.entry

app.put '/api/entry/:entryId', (req, res) ->
  ENTRIES[req.entry.id].title = req.body.title

# Actions

app.post '/api/refresh/:feedId', (req, res) ->
  console.log "Refresh called on feed #{req.feed.id}"

app.post '/api/read/:feedId', (req, res) ->
  console.log "Mark as Read called on feed #{req.feed.id}"

app.listen(3000)
console.log "PaperBox on port %d", app.address().port
