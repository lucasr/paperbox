PaperBox.ViewMode =
    SUMMARY  : 'summary'
    ARTICLES : 'articles'


class PaperBox.Entry extends Backbone.Model
  UNTITLED: 'Untitled'

  url: -> "/api/entry/#{@id}"

  initialize: ->
    @set 'title', @UNTITLED if @get("content")?


class PaperBox.Entries extends Backbone.Collection
  model: PaperBox.Entry

  url: ->
    null if not @feed?
    "/api/feed/#{@feed.id}/entries"

  comparator: (entry) ->
    entry.get 'date'

  setFeed: (feed) ->
    return if feed is @feed

    @feed = feed

    @fetch() if @feed?


class PaperBox.EntryView extends Backbone.View
  MAX_CHARS: 190
  TITLE_MAX_CHARS: 110

  events:
    'click': 'onClick'

  tagName: 'div'

  summaryTemplate: _.template $('#summary-entry-template').html()
  articlesTemplate: _.template $('#articles-entry-template').html()

  initialize: (options) ->
    @viewMode = options.viewMode
    @model.bind 'change', @render

  renderForSummaryMode: ->
    $(@el).html @summaryTemplate()

    title = @model.get 'title'
    body = @model.get 'body'

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

    @$('.body').html "<b>#{title}</b> #{body}"

  renderForArticlesMode: ->
    $(@el).html @articlesTemplate()

    @$('.title h1').text @model.get 'title'
    @$('.body').html @model.get 'body'

  render: =>
    switch @viewMode
      when PaperBox.ViewMode.SUMMARY then @renderForSummaryMode()
      when PaperBox.ViewMode.ARTICLES then @renderForArticlesMode()

    $(@el).addClass 'entry'
    $(@el).attr 'id', 'entry-' + @model.get 'id'

    @

  onClick: =>
    if @viewMode is PaperBox.ViewMode.SUMMARY
      @trigger 'activate', @model

class PaperBox.EntriesView extends Backbone.View
  el: $('#content')

  initialize: ->
    @activeEntry = null
    @viewMode = null
    @feed = null

    @trackScrollPosition()

  trackScrollPosition: ->
    $(window).scroll @onWindowScroll

  fetchEntries: ->
    return if not @feed?

    if not @entries?
      @entries = new PaperBox.Entries

      @entries.bind 'add', @onAddEntry
      @entries.bind 'refresh', @onRefreshEntries

    @entries.setFeed @feed

  getElementForEntry: (entry) ->
    $("[id=entry-#{entry.id}]")

  setEntryElementIsActive: (el, isActive) ->
    $(el).toggleClass 'active', isActive

  setActiveEntry: (activeEntry) ->
    return if activeEntry is @activeEntry

    if @activeEntry?
      el = @getElementForEntry @activeEntry
      @setEntryElementIsActive el, off

    @activeEntry = activeEntry

    if @activeEntry?
      el = @getElementForEntry @activeEntry
      @setEntryElementIsActive el, on

  updateActiveEntryFromScroll: ->
    # FIXME: This is highly inefficient. We should come up
    # with a better way to update active entry from scroll

    windowTop = $(window).scrollTop()
    windowHeight = $(window).height()
    headerHeight = $('#header').height()

    $(@el).children().each (index, el) =>
      top = $(el).offset().top - headerHeight

      if windowTop <= top <= windowTop + windowHeight
        @setActiveEntry @entries.at index
        false

  getEntryViewScrollTop: (entry) ->
    return if not entry?

    # We have to compensate the header height when setting
    # the scroll top as the #content div is offset by its
    # height
    $("#entry-#{entry.id}").offset().top - $('#header').height()

  scrollToActiveEntry: ->
    return if not @activeEntry?

    # Scroll to the activated entry in full view mode
    $(window).scrollTop @getEntryViewScrollTop @activeEntry

  createEntryView: (entry) ->
    view = new PaperBox.EntryView model: entry, viewMode: @viewMode
    view.bind 'activate', @onEntryActivate

    @setEntryElementIsActive view.el, on if entry is @activeEntry

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

    # Update scroll position to show active entry on top
    @scrollToActiveEntry()

  setFeed: (feed) ->
    return if feed is @feed

    @feed = feed

    # Unset active entry for clarity
    @setActiveEntry null

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

    @trigger 'view-mode-changed'

  getViewMode: ->
    @viewMode

  goToPreviousEntry: ->
    return if @viewMode is PaperBox.ViewMode.SUMMARY
    index = @entries.indexOf @activeEntry

    if index - 1 >= 0
      @setActiveEntry @entries.at index - 1
      @scrollToActiveEntry()

  goToNextEntry: ->
    return if @viewMode is PaperBox.ViewMode.SUMMARY
    index = @entries.indexOf @activeEntry

    if index + 1 < @entries.size()
      @setActiveEntry @entries.at index + 1
      @scrollToActiveEntry()

  onWindowScroll: =>
    @updateActiveEntryFromScroll()

  onEntryActivate: (entry) =>
    @setActiveEntry entry
    @setViewMode PaperBox.ViewMode.ARTICLES

  onAddEntry: (entry) =>
    @addEntry(entry)

  onRefreshEntries: =>
    # In case of a refresh caused by a change in
    # the selected feed, we reset the active entry
    # to the first entry in the collection
    if not @activeEntry?
      @setActiveEntry @entries.at 0

    @refreshEntries()
