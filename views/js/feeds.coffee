class PaperBox.Feed extends Backbone.Model
  UNTITLED: 'Untitled'

  url: -> "/api/feed/#{@id}"

  initialize: ->
    @set 'name', @UNTITLED if @get("content")?


class PaperBox.Feeds extends Backbone.Collection
  model: PaperBox.Feed

  url: ->
    null if not @category?
    "/api/category/#{@category.id}/feeds"

  initialize: (models, options) ->
    if 'category' of options
      @setCategory options.category

  comparator: (feed) ->
    feed.get 'name'

  setCategory: (category) ->
    return if category is @category
    @category = category


class PaperBox.FeedView extends Backbone.View
  tagName: 'li'

  events:
    'click': 'onClick'

  initialize: ->
    @model.bind 'change', @render

  render: =>
    $(@el).text @model.get 'name'
    $(@el).attr 'id', 'feed-' + @model.get 'id'
    @

  onClick: =>
    @trigger 'activate', @model


class PaperBox.FeedsView extends Backbone.View
  el: $('#feeds-menu')

  initialize: ->
    @state = PaperBox.ViewState.IDLE
    @category = null
    @selected = null

  createFeedView: (feed) ->
    view = new PaperBox.FeedView model: feed
    view.bind 'activate', @onFeedActivate

    view

  addFeed: (feed) =>
    view = @createFeedView feed
    $(@el).append view.render().el

  refreshFeeds: =>
    # Empty the current list of feeds
    # before fetching and adding all
    $(@el).empty()

    return if not @category

    feeds = @category.getFeeds()

    docFragment = document.createDocumentFragment()

    # Append each feed to a document
    # docFragmentment instead of adding each one directly
    # to the document, for better performance
    feeds.each (feed) =>
      view = @createFeedView feed
      docFragment.appendChild view.render().el

    $(@el).append docFragment

  updateSelected: (selected) ->
    return if selected is @selected

    if @selected?
      el = @getElementForFeed @selected
      $(el).removeClass 'selected'

    @selected = selected

    if @selected?
      el = @getElementForFeed @selected
      $(el).addClass 'selected'

    @trigger 'selected-changed'

  setState: (state) ->
    return if state is @state

    @state = state

    @trigger 'state-changed'

  getState: ->
    @state

  getSelected: ->
    @selected

  selectFeedFromId: (feedId) ->
    return if not @category?

    feeds = @category.getFeeds()
    feed = feeds.detect (f) -> f.id is feedId

    @updateSelected feed

  selectFeedFromIndex: (index) ->
    return if not @category?

    feeds = @category.getFeeds()
    @updateSelected feeds.at index

  goToPreviousFeed: ->
    return if not @category?

    feeds = @category.getFeeds()
    index = feeds.indexOf @selected

    if index - 1 >= 0
      @updateSelected feeds.at index - 1

  goToNextFeed: ->
    return if not @category?

    feeds = @category.getFeeds()
    index = feeds.indexOf @selected

    if index + 1 < feeds.size()
      @updateSelected feeds.at index + 1

  setCategory: (category) ->
    return if category is @category

    @setState PaperBox.ViewState.LOADING

    if @category?
      feeds = @category.getFeeds()
      feeds.unbind 'add', @onAddFeed
      feeds.unbind 'refresh', @onRefreshFeeds

    @category = category

    if @category?
      feeds = @category.getFeeds()
      feeds.bind 'add', @onAddFeed
      feeds.bind 'refresh', @onRefreshFeeds

    @refreshFeeds()
    @setState PaperBox.ViewState.READY

  getElementForFeed: (feed) ->
    $("li[id=feed-#{feed.id}]")

  onFeedActivate: (feed) =>
    @updateSelected feed

  onAddFeed: (feed) =>
    @addFeed(feed)

  onRefreshFeeds: =>
    @refreshFeeds()
