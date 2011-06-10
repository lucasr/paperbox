PaperBox.EntriesViewMode =
    OVERVIEW : 'overview'
    FULL     : 'full'

class PaperBox.Entry extends Backbone.Model
  UNTITLED: 'Untitled'

  initialize: ->
    @set 'title', @UNTITLED if @get("content")?


class PaperBox.Entries extends Backbone.Collection
  model: PaperBox.Entry

  initialize: (models, options) ->
    if 'category' of options and 'feed' of options
      @setCategoryAndFeed options.category, options.feed

  url: ->
    null if not @category? or not @feed?
    "/api/categories/#{@category.id}/feeds/#{@feed.id}/entries"

  comparator: (entry) ->
    entry.get 'date'

  setCategoryAndFeed: (category, feed) ->
    return if category is @category and feed is @feed

    @category = category
    @feed = feed

    @fetch() if @category? and @feed?


class PaperBox.EntryView extends Backbone.View
  MAX_CHARS: 210
  TITLE_MAX_CHARS: 110

  events:
    'click': 'onClick'

  tagName: 'div'

  template: _.template $('#entry-template').html()

  initialize: (options) ->
    @viewMode = options.viewMode
    @model.bind 'change', @render

  render: =>
    $(@el).html @template()
    $(@el).addClass 'entry'
    $(@el).attr 'id', 'entry-' + @model.get 'id'

    title = @model.get 'title'
    body = @model.get 'body'

    if @viewMode is PaperBox.EntriesViewMode.OVERVIEW
      # Truncate and ellipsize title text if necessary
      # We allow a maximum of TITLE_MAX_CHARS chars in
      # the title
      if title.length > @TITLE_MAX_CHARS
        title = title.substring(0, @TITLE_MAX_CHARS - 3) + "..."

      # Strip all HTML tags from body text
      body = body.replace /(<([^>]+)>)/ig, ''

      # Truncate and ellipsize body text if necessary
      if body.length > @MAX_CHARS - title.length
        body = body.substring(0, @MAX_CHARS - title.length - 1) + "..."

      # The whole entry content is set inside the title
      # h1 tag for simplicity
      @$('.title h1').html "<b>#{title}</b> #{body}"

      # The #content element is not used so we remove it
      @$('.content').remove()
    else
      @$('.title h1').text title
      @$('.content').html body

    @

  onClick: =>
    if @viewMode is PaperBox.EntriesViewMode.OVERVIEW
      @trigger 'activate', @model

class PaperBox.EntriesView extends Backbone.View
  el: $('#content')

  initialize: ->
    @activeEntry = null
    @viewMode = null
    @category = null
    @feed = null

  fetchEntries: ->
    return if not @category? or not @feed?

    if @entries?
      @entries.setCategoryAndFeed @category, @feed
    else
      options =
        category: @category
        feed: @feed

      @entries = new PaperBox.Entries [], options

      @entries.bind 'add', @onAddEntry
      @entries.bind 'refresh', @onRefreshEntries

      @entries.fetch()

  getElementForEntry: (entry) ->
    $("[id=entry-#{entry.id}]")

  setActiveEntry: (activeEntry) ->
    return if activeEntry is @activeEntry

    if @activeEntry?
      el = @getElementForEntry @activeEntry
      $(el).removeClass 'active'

    @activeEntry = activeEntry

    if @activeEntry?
      el = @getElementForEntry @activeEntry
      $(el).addClass 'active'

  createEntryView: (entry) ->
    view = new PaperBox.EntryView model: entry, viewMode: @viewMode
    view.bind 'activate', @onEntryActivate

    view

  addEntry: (entry) =>
    view = @createEntryView entry
    $(@el).append view.render().el

  refreshEntries: =>
    return if not @entries?

    # Empty the current list of entries
    # before fetching and adding all
    $(@el).empty()

    docFragment = document.createDocumentFragment()

    # Append each entry to a document
    # docFragmentment instead of adding each one directly
    # to the document, for better performance
    @entries.each (entry) =>
      view = @createEntryView entry
      docFragment.appendChild view.render().el

    $(@el).append docFragment

  setCategoryAndFeed: (category, feed) ->
    return if category is @category and feed is @feed

    @category = category
    @feed = feed

    @fetchEntries()

  setViewMode: (viewMode) ->
    return if viewMode is @viewMode

    # Remove class corresponding to previous mode
    $('#content').removeClass @viewMode if @viewMode?

    @viewMode = viewMode

    # Add class corresponding to new mode
    $('#content').addClass @viewMode if @viewMode?

    # We could re-render all individual elements in the
    # container but that would involve a lot of relayouts
    # and redraws. We better just empty the container and
    # insert all re-rendered elements at once
    @refreshEntries()

  onEntryActivate: (entry) =>
    @trigger 'entry-activate', entry

  onAddEntry: (entry) =>
    @addEntry(entry)

  onRefreshEntries: =>
    @refreshEntries()
