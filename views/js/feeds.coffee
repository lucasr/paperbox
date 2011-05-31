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

    initialize: ->
        @model.bind 'change', @render

    render: =>
        $(@el).text @model.get 'name'
        $(@el).attr 'id', 'feed-' + @model.get 'id'
        @


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

    addFeed: (feed) =>
        view = new PaperBox.FeedView model: feed
        $(@el).append view.render().el

    refreshFeeds: =>
        # Empty the current list of feeds
        # before fetching and adding all
        $(@el).empty()

        # Append each feed to the list
        @feeds.each @addFeed

    setCategory: (category) ->
        return if category is @category

        @category = category
        @fetchFeeds()

    onAddFeed: (feed) =>
        @addFeed(feed)

    onRefreshFeeds: =>
        @refreshFeeds()
