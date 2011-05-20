http = require "http"

http.createServer (req, res) ->
    res.writeHead 200, 'Content-type': 'text/plain'
    res.end 'Coming soon!'
.listen 2011

console.log 'Running!'
