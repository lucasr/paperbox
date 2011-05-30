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
