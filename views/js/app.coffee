class PaperBox.AppView extends Backbone.View
  initialize: ->
    @createCategoriesView()
    @createFeedsView()
    @createEntriesView()

  createCategoriesView: ->
    @categoriesView = new PaperBox.CategoriesView
    @categoriesView.bind 'selected-changed', @onCategoryChanged

  createFeedsView: ->
    @feedsView = new PaperBox.FeedsView
    @feedsView.bind 'selected-changed', @onFeedChanged

  createEntriesView: ->
    @entriesView = new PaperBox.EntriesView

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
