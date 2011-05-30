class PaperBox.AppView extends Backbone.View
    initialize: ->
        @fetchCategories()

    fetchCategories: ->
        @categories = new PaperBox.Categories

        @categories.bind 'addCategory', @addCategory
        @categories.bind 'refresh', @addAllCategories
        @categories.bind 'all', @render

        @categories.fetch()

    addCategory: (category) =>
        view = new PaperBox.CategoryView model: category
        $('#categories-menu').append view.render().el

    addAllCategories: =>
        @categories.each @addCategory
