assert = require 'assert'
server = require '../server.coffee'

module.exports =
    'GET /': ->
        assert.response server.app,
                        { url: '/' },
                        status: 200
                        headers: { 'Content-Type': 'text/html; charset=utf-8' },
                        (res) ->
                            assert.includes res.body, '<title>PaperBox</title>'
