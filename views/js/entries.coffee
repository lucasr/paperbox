class PaperBox.Entry extends Backbone.Model
    UNTITLED: 'Untitled'

    initialize: ->
        @set 'title', @UNTITLED if @get("content")?


class PaperBox.Entries extends Backbone.Collection
    model: PaperBox.Entry

    initialize: (models, options) ->
        if 'category' of options and 'feed' of options
            @setCategoryAndFeed options.category, options.feed

    url: ->
        null if not @category? or not @feed?
        "/api/categories/#{@category.id}/feeds/#{@feed.id}/entries"

    comparator: (entry) ->
        entry.get 'date'

    setCategoryAndFeed: (category, feed) ->
        return if category is @category and feed is @feed

        @category = category
        @feed = feed

        @fetch() if @category? and @feed?


class PaperBox.EntryView extends Backbone.View
    tagName: 'div'

    template: _.template $('#entry-template').html()

    initialize: ->
        @model.bind 'change', @render

    render: =>
        $(@el).html @template()
        $(@el).addClass 'entry'
        $(@el).attr 'id', 'entry-' + @model.get 'id'

        @$('.title h1').text @model.get 'title'
        @$('.content').html @model.get 'body'
        @


class PaperBox.EntriesView extends Backbone.View
    el: $('#content')

    initialize: ->
        @category = null
        @feed = null

    fetchEntries: ->
        return if not @category? or not @feed?

        if @entries?
            @entries.setCategoryAndFeed @category, @feed
        else
            options =
                category: @category
                feed: @feed

            @entries = new PaperBox.Entries [], options

            @entries.bind 'add', @onAddEntry
            @entries.bind 'refresh', @onRefreshEntries

            @entries.fetch()

    createEntryView: (entry) ->
        view = new PaperBox.EntryView model: entry

    addEntry: (entry) =>
        view = @createEntryView entry
        $(@el).append view.render().el

    refreshEntries: =>
        # Empty the current list of entries
        # before fetching and adding all
        $(@el).empty()

        docFragment = document.createDocumentFragment()

        # Append each entry to a document
        # docFragmentment instead of adding each one directly
        # to the document, for better performance
        @entries.each (entry) =>
            view = @createEntryView entry
            docFragment.appendChild view.render().el

        $(@el).append docFragment

    setCategoryAndFeed: (category, feed) ->
        return if category is @category and feed is @feed

        @category = category
        @feed = feed

        @fetchEntries()

    onAddEntry: (entry) =>
        @addEntry(entry)

    onRefreshEntries: =>
        @refreshEntries()
