class PaperBox.AppView extends Backbone.View
    initialize: ->
        @createCategoriesView()
        @createFeedsView()

    createCategoriesView: ->
        @categoriesView = new PaperBox.CategoriesView
        @categoriesView.bind 'selected-changed', @onCategoryChanged

    createFeedsView: ->
        @feedsView = new PaperBox.FeedsView
        @feedsView.bind 'selected-changed', @onFeedChanged

    updateHeaderForCategory: (category) ->
        $('#category-title').text category.get 'name'

    updateHeaderForFeed: (feed) ->
        $('#feed-title').text feed.get 'name'

    onCategoryChanged: =>
        category = @categoriesView.getSelected()

        @updateHeaderForCategory category
        @feedsView.setCategory category

    onFeedChanged: =>
        feed = @feedsView.getSelected()
        @updateHeaderForFeed feed
