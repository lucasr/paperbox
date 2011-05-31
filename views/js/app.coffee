class PaperBox.AppView extends Backbone.View
    initialize: ->
        @createCategoriesView()
        @createFeedsView()

    createCategoriesView: ->
        @categoriesView = new PaperBox.CategoriesView
        @categoriesView.bind 'selected-changed', @onCategoryChanged

    createFeedsView: ->
        @feedsView = new PaperBox.FeedsView

    updateHeader: (category) ->
        $('#category-title').text category.get 'name'

    onCategoryChanged: =>
        category = @categoriesView.getSelected()

        @updateHeader category
        @feedsView.setCategory category
