# Scripts prefixed with 'require.order.min!' are loaded in
# the order they appear in the deps list. The order is only
# important for interdependent scripts.
deps = [
  'require.order.min!jquery.min'
  'require.order.min!jquery-ui.custom.min'
  'require.order.min!json2'
  'require.order.min!underscore.min'
  'require.order.min!backbone.min'
  'require.order.min!namespaces'
  'require.order.min!categories'
  'require.order.min!feeds'
  'require.order.min!entries'
  'require.order.min!app'
]

require deps, ->
  # All modules are loaded
  $ ->
    Global.appView = new PaperBox.AppView
