class PaperBox.Feed extends Backbone.Model
    UNTITLED: 'Untitled'

    initialize: ->
        @set 'name', @UNTITLED if @get("content")?


class PaperBox.Feeds extends Backbone.Collection
    model: PaperBox.Feed

    initialize: (models, options) ->
        if 'category' of options
            @setCategory options.category

    url: ->
        null if not @category?
        "/api/categories/#{@category.id}/feeds"

    comparator: (feed) ->
        feed.get 'name'

    setCategory: (category) ->
        return if category is @category

        @category = category
        @fetch() if @category?


class PaperBox.FeedView extends Backbone.View
    tagName: 'li'

    events:
        'click': 'onClick'

    initialize: ->
        @model.bind 'change', @render

    render: =>
        $(@el).text @model.get 'name'
        $(@el).attr 'id', 'feed-' + @model.get 'id'
        @

    onClick: =>
        @trigger 'activate', @model


class PaperBox.FeedsView extends Backbone.View
    el: $('#feeds-menu')

    initialize: ->
        @category = null

    fetchFeeds: ->
        return if not @category?

        if @feeds?
            @feeds.setCategory @category
        else
            @feeds = new PaperBox.Feeds [], category: @category

            @feeds.bind 'add', @onAddFeed
            @feeds.bind 'refresh', @onRefreshFeeds

            @feeds.fetch()

    makeSortable: ->
        $(@el).sortable
            placeholder: 'side-menu-placeholder'
            stop: @onDraggingStop
            update: @onDraggingDone

        $(@el).disableSelection()

    createFeedView: (feed) ->
        new PaperBox.FeedView model: feed

    addFeed: (feed) =>
        view = @createFeedView feed
        $(@el).append view.render().el

    refreshFeeds: =>
        # Empty the current list of feeds
        # before fetching and adding all
        $(@el).empty()

        docFragment = document.createDocumentFragment()

        # Append each feed to a document
        # docFragmentment instead of adding each one directly
        # to the document, for better performance
        @feeds.each (feed) =>
            view = @createFeedView feed
            docFragment.appendChild view.render().el

        $(@el).append docFragment

    setCategory: (category) ->
        return if category is @category

        @category = category
        @fetchFeeds()

    onAddFeed: (feed) =>
        @addFeed(feed)

    onRefreshFeeds: =>
        @refreshFeeds()
