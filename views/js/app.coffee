class PaperBox.AppView extends Backbone.View
    initialize: ->
        @createCategoriesView()
        @createFeedsView()

    createCategoriesView: ->
        @categoriesView = new PaperBox.CategoriesView
        @categoriesView.bind 'selected-changed', @onCategoryChanged

    createFeedsView: ->
        @feedsView = new PaperBox.FeedsView

    onCategoryChanged: =>
        @feedsView.setCategory @categoriesView.getSelected()
