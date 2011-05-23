deps = [
    'jquery.min'
    'json2'
    'underscore.min'
    'backbone.min'
]

alert 'Require'

require deps, ->
    # All modules are loaded
    alert 'Yeah'
