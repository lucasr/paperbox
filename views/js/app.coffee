class PaperBox.AppView extends Backbone.View
    initialize: ->
        @createCategoriesView()

    createCategoriesView: ->
        @categoriesView = new PaperBox.CategoriesView
