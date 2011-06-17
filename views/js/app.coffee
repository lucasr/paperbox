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

  setController: (controller) ->
    @controller = controller

  selectCategoryFromId: (categoryId) ->
    @categoriesView.selectCategoryFromId categoryId

  selectFeedFromId: (feedId) ->
    @feedsView.selectFeedFromId feedId

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

      # 'u' returns to overview
      when 117
        @updateViewMode PaperBox.EntriesViewMode.OVERVIEW
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

    @controller.saveLocation "category/#{category.id}/#{feed.id}"

  onViewModeChanged: () =>
    @updateViewMode @entriesView.getViewMode()

  onViewModeOverview: =>
    @updateViewMode PaperBox.EntriesViewMode.OVERVIEW

  onViewModeFull: =>
    @updateViewMode PaperBox.EntriesViewMode.FULL
