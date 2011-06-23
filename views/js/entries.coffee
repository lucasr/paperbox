PaperBox.ViewMode =
    SUMMARY  : 'summary'
    ARTICLES : 'articles'


class PaperBox.Entry extends Backbone.Model
  UNTITLED: 'Untitled'

  url: -> "/api/entry/#{@id}"

  initialize: ->
    @set 'title', @UNTITLED if not @get('title')?


class PaperBox.Entries extends Backbone.Collection
  model: PaperBox.Entry

  url: ->
    null if not @feed? or not @page?
    "/api/feed/#{@feed.id}/entries/#{@page}"

  initialize: ->
    @hasMore = true

  comparator: (entry) ->
    entry.get 'date'

  fetchMore: ->
    Backbone.sync 'read', @, (resp) =>
      if resp.length is 0
        return @hasMore = false

      models = []

      for m in resp
        models.push new @model m, collection: @

      @add models, silent: true
      @trigger 'add-many', models

    @

  hasMoreEntries: ->
    @hasMore

  setFeedAndPage: (feed, page) ->
    return if feed is @feed and page is @page

    pageChanged = page isnt @page
    @page = page

    feedChanged = feed isnt @feed
    @feed = feed

    if feedChanged
      @hasMore = true
      @fetch()
    else
      @fetchMore()


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

  formatDate: (date) ->
    monthNames = [
      "January"
      "February"
      "March"
      "April"
      "May"
      "June"
      "July"
      "August"
      "September"
      "October"
      "November"
      "December"
    ]

    entryDate = new Date date

    day = entryDate.getDate()
    month = monthNames[entryDate.getMonth()]
    year = entryDate.getFullYear()

    "#{month} #{day}, #{year}"

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

    @$('.info .date').text @formatDate @model.get 'date'
    @$('.info .feed').text @model.get 'feed'
    @$('.body').html "<b>#{title}</b> #{body}"

  renderForArticlesMode: ->
    $(@el).html @articlesTemplate()

    @$('.title h1').text @model.get 'title'
    @$('.title .date').text @formatDate @model.get 'date'
    @$('.title .feed').text @model.get 'feed'
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
    @page = 0

    @scroll =
      headerHeight: $('#header').height()

    @updateScroll()
    @trackScrollPosition()

  trackScrollPosition: ->
    $(window).scroll @onWindowScroll

  fetchEntries: ->
    return if not @feed?

    if not @entries?
      @entries = new PaperBox.Entries

      @entries.bind 'add', @onAddEntry
      @entries.bind 'add-many', @onAddManyEntries
      @entries.bind 'refresh', @onRefreshEntries

    @entries.setFeedAndPage @feed, @page

  maybeFetchMoreEntries: ->
    bottommost = $(document).height() -
                 @scroll.windowHeight - @scroll.headerHeight

    return if @scroll.top isnt bottommost

    if @entries.hasMoreEntries()
      @page++
      @fetchEntries()

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

    $(@el).children().each (index, el) =>
      position = @getElementPosition el

      if @scroll.top <= position.top <= @scroll.bottom
        @setActiveEntry @entries.at index
        false

  scrollToActiveEntry: (options = {}) ->
    return if not @activeEntry?

    position = @getEntryPosition @activeEntry

    if 'toBottom' of options
      scrollTop = @scroll.top + position.bottom - @scroll.bottom
    else
      scrollTop = position.top

    $(window).scrollTop scrollTop

  createEntryView: (entry) ->
    view = new PaperBox.EntryView model: entry, viewMode: @viewMode
    view.bind 'activate', @onEntryActivate

    @setEntryElementIsActive view.el, on if entry is @activeEntry

    view

  addEntry: (entry) =>
    view = @createEntryView entry
    $(@el).append view.render().el

  addManyEntries: (entries) =>
    docFragment = document.createDocumentFragment()

    # Append each entry to a document
    # docFragmentment instead of adding each one directly
    # to the document, for better performance
    for entry in entries
      view = @createEntryView entry
      docFragment.appendChild view.render().el

    $(@el).append docFragment

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

  updateScroll: ->
    @scroll.windowHeight = $(window).height() - @scroll.headerHeight
    @scroll.top = $(window).scrollTop()
    @scroll.bottom = @scroll.top + @scroll.windowHeight

  getElementPosition: (el) ->
    position = {}

    position.top = $(el).offset().top - @scroll.headerHeight
    position.bottom = position.top + $(el).outerHeight()

    position

  getEntryPosition: (entry) ->
    el = @getElementForEntry entry
    @getElementPosition el

  selectEntryFromIndex: (index) ->
    @setActiveEntry @entries.at index

    shouldScroll = true
    options = {}

    if @viewMode is PaperBox.ViewMode.SUMMARY
      position = @getEntryPosition @activeEntry

      shouldScroll = position.top < @scroll.top or
                     position.bottom > @scroll.bottom

      options.toBottom = true if position.bottom > @scroll.bottom

    @scrollToActiveEntry(options) if shouldScroll

  setFeed: (feed) ->
    return if feed is @feed

    @page = 0
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
    index = @entries.indexOf @activeEntry

    if index - 1 >= 0
      @selectEntryFromIndex index - 1

  goToNextEntry: ->
    index = @entries.indexOf @activeEntry

    if index + 1 < @entries.size()
      @selectEntryFromIndex index + 1

  onWindowScroll: =>
    @updateScroll()

    updateActiveFromScroll = true

    if @viewMode is PaperBox.ViewMode.SUMMARY and @activeEntry?
      position = @getEntryPosition @activeEntry

      # While in summary mode, we should only update the active
      # entry if the currently active entry is not visible
      updateActiveFromScroll = position.top > @scroll.bottom or
                               position.bottom < @scroll.top

    @updateActiveEntryFromScroll() if updateActiveFromScroll

    @maybeFetchMoreEntries()

  onEntryActivate: (entry) =>
    @setActiveEntry entry
    @setViewMode PaperBox.ViewMode.ARTICLES

  onAddEntry: (entry) =>
    @addEntry entry

  onAddManyEntries: (entries) =>
    @addManyEntries entries

  onRefreshEntries: =>
    # In case of a refresh caused by a change in
    # the selected feed, we reset the active entry
    # to the first entry in the collection
    if not @activeEntry?
      @setActiveEntry @entries.at 0

    @refreshEntries()
