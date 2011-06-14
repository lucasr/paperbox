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

  createCategoriesView: ->
    @categoriesView = new PaperBox.CategoriesView
    @categoriesView.bind 'selected-changed', @onCategoryChanged

  createFeedsView: ->
    @feedsView = new PaperBox.FeedsView
    @feedsView.bind 'selected-changed', @onFeedChanged

  createEntriesView: ->
    @entriesView = new PaperBox.EntriesView
    @entriesView.bind 'entry-activate', @onEntryActivate

  updateViewMode: (viewMode = PaperBox.EntriesViewMode.OVERVIEW) ->
    @entriesView.setViewMode viewMode

    # Add 'selected' class to the respective mode button
    for viewId, aViewMode of PaperBox.EntriesViewMode
      if aViewMode is viewMode
        $("#view-mode-#{aViewMode}").addClass 'selected'
      else
        $("#view-mode-#{aViewMode}").removeClass 'selected'

  updateHeaderForCategory: (category) ->
    $('#category-title').text category.get 'name'

  updateHeaderForFeed: (feed) ->
    $('#feed-title').text feed.get 'name'

  updateScroll: ->
    $('html, body').scrollTop(0)

  onCategoryChanged: =>
    category = @categoriesView.getSelected()

    @updateHeaderForCategory category
    @feedsView.setCategory category

  onFeedChanged: =>
    category = @categoriesView.getSelected()
    feed = @feedsView.getSelected()

    @updateScroll()
    @updateHeaderForFeed feed
    @entriesView.setCategoryAndFeed category, feed

  onEntryActivate: (entry) =>
    @updateViewMode PaperBox.EntriesViewMode.FULL

  onViewModeOverview: =>
    @updateViewMode PaperBox.EntriesViewMode.OVERVIEW

  onViewModeFull: =>
    @updateViewMode PaperBox.EntriesViewMode.FULL
