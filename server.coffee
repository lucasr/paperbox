express = require 'express'
stylus = require 'stylus'
fs = require 'fs'

app = module.exports = express.createServer()

app.configure ->
    app.set 'views', __dirname + '/views'
    app.set 'view engine', 'jade'

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
    app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
    app.use express.errorHandler()

app.get '/', (req, res) ->
    res.render 'index', title: 'PaperBox'

app.listen(3000)
console.log "PaperBox on port %d", app.address().port
