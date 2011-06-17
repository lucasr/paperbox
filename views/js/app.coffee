class PaperBox.AppView extends Backbone.View
  el: $('body')

  events:
    'click #view-mode-overview': 'onViewModeOverview'
    'click #view-mode-full': 'onViewModeFull'

  initialize: ->
    @createCategoriesView()
    @createFeedsView()
    @createEntriesView()
    @updateViewMode()
    @setupGlobalShortcuts()

  createCategoriesView: ->
    @categoriesView = new PaperBox.CategoriesView
    @categoriesView.bind 'selected-changed', @onCategoryChanged

  createFeedsView: ->
    @feedsView = new PaperBox.FeedsView
    @feedsView.bind 'selected-changed', @onFeedChanged

  createEntriesView: ->
    @entriesView = new PaperBox.EntriesView
    @entriesView.bind 'view-mode-changed', @onViewModeChanged

  updateViewMode: (viewMode = PaperBox.EntriesViewMode.OVERVIEW) ->
    @entriesView.setViewMode viewMode

    # Add 'selected' class to the respective mode button
    for viewId, aViewMode of PaperBox.EntriesViewMode
      if aViewMode is viewMode
        $("#view-mode-#{aViewMode}").addClass 'selected'
      else
        $("#view-mode-#{aViewMode}").removeClass 'selected'

  setupGlobalShortcuts: ->
    $(document).keypress @onDocumentKeyPress

  updateHeaderForCategory: (category) ->
    $('#category-title').text category.get 'name'

  updateHeaderForFeed: (feed) ->
    $('#feed-title').text feed.get 'name'

  toggleViewMode: ->
    if @entriesView.getViewMode() is PaperBox.EntriesViewMode.FULL
      viewMode = PaperBox.EntriesViewMode.OVERVIEW
    else
      viewMode = PaperBox.EntriesViewMode.FULL

    @updateViewMode viewMode

  goToPreviousCategory: ->
    @categoriesView.goToPreviousCategory()

  goToNextCategory: ->
    @categoriesView.goToNextCategory()

  goToPreviousFeed: ->
    @feedsView.goToPreviousFeed()

  goToNextFeed: ->
    @feedsView.goToNextFeed()

  goToPreviousEntry: ->
    @entriesView.goToPreviousEntry()

  goToNextEntry: ->
    @entriesView.goToNextEntry()

  onDocumentKeyPress: (event) =>
    handled = false

    switch event.charCode
      # 'd' selects previous feed
      when 100
        @goToPreviousCategory()
        handled = true

      # 'f' selects next feed
      when 102
        @goToNextCategory()
        handled = true

      # 'g' selects previous feed
      when 103
        @goToPreviousFeed()
        handled = true

      # 'h' selects next feed
      when 104
        @goToNextFeed()
        handled = true

      # 'j' toggles view modes
      when 106
        @goToPreviousEntry()
        handled = true

      # 'k' toggles goTo modes
      when 107
        @goToNextEntry()
        handled = true

      # 'v' toggles view modes
      when 118
        @toggleViewMode()
        handled = true

    if handled
      event.preventDefault()
      event.stopPropagation()

  onCategoryChanged: =>
    category = @categoriesView.getSelected()

    @updateHeaderForCategory category
    @feedsView.setCategory category

  onFeedChanged: =>
    category = @categoriesView.getSelected()
    feed = @feedsView.getSelected()

    @updateHeaderForFeed feed
    @entriesView.setFeed feed

  onViewModeChanged: () =>
    @updateViewMode @entriesView.getViewMode()

  onViewModeOverview: =>
    @updateViewMode PaperBox.EntriesViewMode.OVERVIEW

  onViewModeFull: =>
    @updateViewMode PaperBox.EntriesViewMode.FULL
