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
        $(@el).attr 'id', 'category-' + @model.get 'id'
        $(@el).data 'category-order', @model.get 'order'
        @

class PaperBox.CategoriesView extends Backbone.View
    el: $('#categories-menu')

    initialize: ->
        @fetchCategories()
        @makeSortable()

    fetchCategories: ->
        @categories = new PaperBox.Categories

        @categories.bind 'addCategory', @addCategory
        @categories.bind 'refresh', @addAllCategories

        @categories.fetch()

    makeSortable: ->
        $(@el).sortable
            placeholder: 'side-menu-placeholder'
            stop: @onDraggingStop
            update: @onDraggingDone

        $(@el).disableSelection()

    addCategory: (category) =>
        view = new PaperBox.CategoryView model: category
        $(@el).append view.render().el

    addAllCategories: =>
        # Empty the current list of categories
        # before fetching and adding all
        $(@el).empty()

        # Append each category to the list
        @categories.each @addCategory

    onDraggingStop: (event, ui) =>
        newOrder = $(ui.item).index()
        previousOrder = $(ui.item).data 'category-order'

        return if newOrder is previousOrder

        # Only update the set of list items that actually
        # need changes in the order property.
        for index in [previousOrder..newOrder]
            do (index) =>
                model = @categories.at index

                # We're selecting list items by id here to avoid
                # using an extra custom jQuery plugin to do data-based
                # selection. List item ids are set in CategoryView.
                el = $("li[id=category-#{model.id}]")

                newIndex = $(el).index()

                # We use 'silent' option here to avoid
                # broadcasting 'change' anywhere
                model.set { 'order': newIndex },
                          { 'silent': true }

                # Update element data with new index
                $(el).data 'category-order', newIndex

                model.save()

        @categories.sort silent: true
