express = require 'express'
stylus = require 'stylus'

app = module.exports = express.createServer()

app.configure ->
    app.set 'views', __dirname + '/views'
    app.set 'view engine', 'jade'

    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use express.cookieParser()
    app.use express.session secret: 'paperbox'

    app.use stylus.middleware src: __dirname + '/public'

    app.use app.router
    app.use express.static __dirname + '/public'

app.configure 'development', ->
    app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
    app.use express.errorHandler()

app.get '/', (req, res) ->
    res.render 'index', title: 'PaperBox'

app.listen(3000)
console.log "PaperBox on port %d", app.address().port
