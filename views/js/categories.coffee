class PaperBox.Category extends Backbone.Model
    UNTITLED: 'Untitled'

    initialize: ->
        @set 'name', @UNTITLED if @get("content")?


class PaperBox.Categories extends Backbone.Collection
    url: '/api/categories'

    model: PaperBox.Category

    nextOrder: ->
        1 if not @length
        @last().get('order') + 1

    comparator: (category) ->
        category.get 'order'


class PaperBox.CategoryView extends Backbone.View
    tagName: 'li'

    initialize: ->
        @model.bind 'change', @render

    render: =>
        $(@el).text @model.get 'name'
        @

class PaperBox.CategoriesView extends Backbone.View
    el: $('#categories-menu')

    initialize: ->
        @fetchCategories()

    fetchCategories: ->
        @categories = new PaperBox.Categories

        @categories.bind 'addCategory', @addCategory
        @categories.bind 'refresh', @addAllCategories

        @categories.fetch()

    addCategory: (category) =>
        view = new PaperBox.CategoryView model: category
        $(@el).append view.render().el

    addAllCategories: =>
        # Empty the current list of categories
        # before fetching and adding all
        $(@el).empty()

        # Append each category to the list
        @categories.each @addCategory
