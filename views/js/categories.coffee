class PaperBox.Category extends Backbone.Model
  UNTITLED: 'Untitled'

  url: -> "/api/category/#{@id}"

  initialize: ->
    @set 'name', @UNTITLED if @get("content")?
    @feeds = new PaperBox.Feeds @get 'feeds', category: @

  getFeeds: ->
    @feeds


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

  template: _.template $('#category-template').html()

  events:
    'click': 'onClick'

  initialize: ->
    @model.bind 'change', @render

  render: =>
    $(@el).html @template()
    $(@el).attr 'id', 'category-' + @model.get 'id'
    $(@el).data 'category-order', @model.get 'order'

    @$('.title').text @model.get 'name'

    @

  onClick: =>
    @trigger 'activate', @model

class PaperBox.CategoriesView extends Backbone.View
  el: $('#categories-menu')

  initialize: ->
    @state = PaperBox.ViewState.IDLE
    @selected = null

    @fetchCategories()
    @makeSortable()

  fetchCategories: ->
    @setState PaperBox.ViewState.LOADING

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

  createCategoryView: (category) ->
    view = new PaperBox.CategoryView model: category
    view.bind 'activate', @onCategoryActivate

    view

  addCategory: (category) =>
    view = @createCategoryView category
    $(@el).append view.render().el

  refreshCategories: =>
    # Empty the current list of categories
    # before fetching and adding all
    $(@el).empty()

    docFragment = document.createDocumentFragment()

    # Append each category to a document
    # docFragmentment instead of adding each one directly
    # to the document, for better performance
    @categories.each (category) =>
      view = @createCategoryView category
      docFragment.appendChild view.render().el

    $(@el).append docFragment

  updateSelected: (selected) ->
    return if selected is @selected

    if @selected?
      el = @getElementForCategory @selected
      $(el).removeClass 'selected'

    @selected = selected

    if @selected?
      el = @getElementForCategory @selected
      $(el).addClass 'selected'

    @trigger 'selected-changed'

  setState: (state) ->
    return if state is @state

    @state = state

    @trigger 'state-changed'

  getState: ->
    @state

  goToPreviousCategory: ->
    index = @categories.indexOf @selected

    if index - 1 >= 0
      @updateSelected @categories.at index - 1

  goToNextCategory: ->
    index = @categories.indexOf @selected

    if index + 1 < @categories.size()
      @updateSelected @categories.at index + 1

  getSelected: ->
    @selected

  selectCategoryFromId: (categoryId) ->
    category = @categories.detect (c) -> c.id is categoryId
    @updateSelected category if category?

  selectCategoryFromIndex: (index) ->
    @updateSelected @categories.at index

  getElementForCategory: (category) ->
    $("li[id=category-#{category.id}]")

  onCategoryActivate: (category) =>
    @updateSelected category

  onAddCategory: (category) =>
    @addCategory category

  onRefreshCategories: =>
    @refreshCategories()
    @setState PaperBox.ViewState.READY

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
