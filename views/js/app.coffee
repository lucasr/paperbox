PaperBox.ViewState =
  IDLE    : 0
  LOADING : 1
  READY   : 2


class PaperBox.AppController extends Backbone.Controller
  routes:
    'category/:categoryId': 'category'
    'category/:categoryId/:feedId': 'category'

  category: (categoryId, feedId) ->
    if categoryId?
      categoryId = parseInt categoryId, 10
      @appView.selectCategoryFromId categoryId

    if feedId?
      feedId = parseInt feedId, 10
      @appView.selectFeedFromId feedId

  setAppView: (appView) ->
    @appView = appView


class PaperBox.AppView extends Backbone.View
  el: $('body')

  events:
    'click #view-mode-summary': 'onViewModeSummary'
    'click #view-mode-articles': 'onViewModeArticles'
    'click #tools-refresh-button': 'onRefreshClicked'
    'click #tools-read-button': 'onMarkAsReadClicked'

  initialize: ->
    @initialized = false

    @createCategoriesView()
    @createFeedsView()
    @createEntriesView()
    @updateViewMode()
    @setupGlobalShortcuts()

  createCategoriesView: ->
    @categoriesView = new PaperBox.CategoriesView
    @categoriesView.bind 'selected-changed', @onCategoryChanged
    @categoriesView.bind 'state-changed', @onCategoriesViewStateChanged

  createFeedsView: ->
    @feedsView = new PaperBox.FeedsView
    @feedsView.bind 'selected-changed', @onFeedChanged

  createEntriesView: ->
    @entriesView = new PaperBox.EntriesView
    @entriesView.bind 'view-mode-changed', @onViewModeChanged

  updateViewMode: (viewMode = PaperBox.ViewMode.SUMMARY) ->
    @entriesView.setViewMode viewMode

    # Add 'selected' class to the respective mode button
    for viewId, aViewMode of PaperBox.ViewMode
      if aViewMode is viewMode
        $("#view-mode-#{aViewMode}").addClass 'selected'
      else
        $("#view-mode-#{aViewMode}").removeClass 'selected'

  refreshFeed: ->
    feed = @feedsView.getSelected()
    $.post "/api/refresh/#{feed.id}", {}

  markFeedAsRead: ->
    feed = @feedsView.getSelected()
    $.post "/api/read/#{feed.id}", {}

  setupGlobalShortcuts: ->
    $(document).keypress @onDocumentKeyPress

  updateHeaderForCategory: (category) ->
    $('#category-title').text category.get 'name'

  updateHeaderForFeed: (feed) ->
    $('#feed-title').text feed.get 'name'

  maybeInitSelection: ->
    return if @initialized

    # This will handle any pending client-side routes on
    # startup. If a route is activated by the initial fragment
    # categoryIdToSelect and feedIdToSelect might be set.
    # If no fragment is used, we simply select the first
    # category and feed from the list.
    Backbone.history.start()

    @initialized = true

    if @categoryIdToSelect?
      @categoriesView.selectCategoryFromId @categoryIdToSelect
      delete @categoryIdToSelect
    else
      @categoriesView.selectCategoryFromIndex 0

    if @feedIdToSelect?
      @feedsView.selectFeedFromId @feedIdToSelect
      delete @feedIdToSelect
    else
      @feedsView.selectCategoryFeed()

  updateFromState: ->
    state = @categoriesView.getState()

    if state is PaperBox.ViewState.READY
      @maybeInitSelection()

  toggleViewMode: ->
    if @entriesView.getViewMode() is PaperBox.ViewMode.ARTICLES
      viewMode = PaperBox.ViewMode.SUMMARY
    else
      viewMode = PaperBox.ViewMode.ARTICLES

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

  setController: (controller) ->
    @controller = controller

  selectCategoryFromId: (categoryId) ->
    if @initialized
      @categoriesView.selectCategoryFromId categoryId
    else
      @categoryIdToSelect = categoryId

  selectFeedFromId: (feedId) ->
    if @initialized
      @feedsView.selectFeedFromId feedId
    else
      @feedIdToSelect = feedId

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

      # 'u' returns to summary
      when 117
        if @entriesView.getViewMode() is PaperBox.ViewMode.ARTICLES
          @updateViewMode PaperBox.ViewMode.SUMMARY
        else
          @refreshFeed()

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

    @feedsView.selectCategoryFeed()

  onCategoriesViewStateChanged: =>
    @updateFromState()

  onFeedChanged: =>
    category = @categoriesView.getSelected()
    feed = @feedsView.getSelected()

    @updateHeaderForFeed feed
    @entriesView.setFeed feed

    @controller.saveLocation "category/#{category.id}/#{feed.id}"

  onViewModeChanged: () =>
    @updateViewMode @entriesView.getViewMode()

  onViewModeSummary: =>
    @updateViewMode PaperBox.ViewMode.SUMMARY

  onViewModeArticles: =>
    @updateViewMode PaperBox.ViewMode.ARTICLES

  onRefreshClicked: =>
    @refreshFeed()

  onMarkAsReadClicked: =>
    @markFeedAsRead()
