express = require 'express'
stylus = require 'stylus'
fs = require 'fs'

app = module.exports = express.createServer()

CATEGORIES = [
    { id: 1, name: 'Cat 0', order: 0 }
    { id: 2, name: 'Cat 1', order: 1 }
    { id: 3, name: 'Cat 2', order: 2 }
    { id: 4, name: 'Cat 3', order: 3 }
    { id: 5, name: 'Cat 4', order: 4 }
    { id: 6, name: 'Cat 5', order: 5 }
    { id: 7, name: 'Cat 6', order: 6 }
    { id: 8, name: 'Cat 7', order: 7 }
    { id: 9, name: 'Cat 8', order: 8 }
    { id: 10, name: 'Cat 9', order: 9 }
]

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

loadCategory = (req, res, next, categoryId) ->
    # The categoryId might be undefined when using
    # the /categories with no id. Don't do anything
    # in this case.
    return next() if categoryId is undefined

    id = parseInt categoryId, 10

    found = CATEGORIES.filter (c) -> id is c.id

    if found.length isnt 1
        return next(new Error('Unable to find category'))

    req.category = found[0]

    next()

app.param 'categoryId', loadCategory

app.get '/api/categories/:categoryId?', (req, res) ->
    if 'category' of req
        res.send req.category
    else
        res.send CATEGORIES

app.put '/api/categories/:categoryId', (req, res) ->
    req.category.name = req.body.name
    req.category.order = req.body.order

app.listen(3000)
console.log "PaperBox on port %d", app.address().port
