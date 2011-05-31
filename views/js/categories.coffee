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

    events:
        'click': 'onClick'

    initialize: ->
        @model.bind 'change', @render

    render: =>
        $(@el).text @model.get 'name'
        $(@el).attr 'id', 'category-' + @model.get 'id'
        $(@el).data 'category-order', @model.get 'order'

        # FIXME: Should move the construction of CategoryView
        # to a separate template hidden element
        $(@el).append '<div class="handle"/>'
        @

    onClick: =>
        @trigger 'activate', @model

class PaperBox.CategoriesView extends Backbone.View
    el: $('#categories-menu')

    initialize: ->
        @fetchCategories()
        @makeSortable()

    fetchCategories: ->
        @categories = new PaperBox.Categories

        @categories.bind 'add', @onAddCategory
        @categories.bind 'refresh', @onRefreshCategories

        @categories.fetch()

    makeSortable: ->
        $(@el).sortable
            placeholder: 'side-menu-placeholder'
            handle: '.handle'
            stop: @onDraggingStop
            update: @onDraggingDone

        $(@el).disableSelection()

    addCategory: (category) =>
        view = new PaperBox.CategoryView model: category
        $(@el).append view.render().el

    refreshCategories: =>
        # Empty the current list of categories
        # before fetching and adding all
        $(@el).empty()

        # Append each category to the list
        @categories.each @addCategory

    getElementForCategory: (category) ->
        $("li[id=category-#{category.id}]")

    onAddCategory: (category) =>
        @addCategory category

    onRefreshCategories: =>
        @refreshCategories()

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
                el = @getElementForCategory model

                newIndex = $(el).index()

                # We use 'silent' option here to avoid
                # broadcasting 'change' anywhere
                model.set { 'order': newIndex },
                          { 'silent': true }

                # Update element data with new index
                $(el).data 'category-order', newIndex

                model.save()

        @categories.sort silent: true
