class Backbone.PagedCollection extends Backbone.Collection
  @pagify: (collection)->
    if collection.paged? and collection? and collection.paged.fullCollection == collection
      return collection.paged.fullCollection
    new Backbone.PagedCollection([], collection)

  initialize: (models, fullCollection)->    
    @currentPage = 1
    @clientPerPage = 4
    @serverPerPage = 20
    @fetchOffset = 0
    @serverPage = 1
    @totalItems = null
    @bootstrapedItems = 0

    @fullCollection = fullCollection
    @fullCollection.paged ||= {}
    for field, value of @fullCollection.paged
      @[field] ||= value

    @fullCollection.paged = @
    @setPageModels()

  setPageModels: ->
    models = []
    fromIndex = (@currentPage - 1) * @clientPerPage
    toIndex = @currentPage * @clientPerPage
    @reset(@fullCollection.slice(fromIndex, toIndex))

  isFetchRequired: ->
    minimumItemsCount = (@currentPage - 1) * @clientPerPage + 1 + @fetchOffset
    @fullCollection.length != @totalItems and @fullCollection.length < minimumItemsCount

  isFullyCached: -> @totalItems == @length

  changeCurrentPage: (pageNo)->
    @currentPage = pageNo
    
    if @bootstrapedItems > @fullCollection.length
      @totalItems ||= @fullCollection.length 
    
    @isFirstPage = false
    @isLastPage = false

    if @currentPage <= 1
      @isFirstPage = true
      @currentPage = 1
    if @totalItems? and @totalItems <= @currentPage * @clientPerPage
      @isLastPage = true
      while @totalItems <= (@currentPage - 1) * @clientPerPage
        @currentPage -= 1

    @serverPage = Math.ceil(
      (@fetchOffset - @bootstrapedItems + @currentPage * @clientPerPage) / @serverPerPage
    )

  goTo: (pageNo, options = {})->
    @changeCurrentPage(pageNo)
    if options.fetch != false and @isFetchRequired()
      @fullCollection.fetch
        remove: false
        success: =>
          @setPageModels()
          options.success(@) if options.success?
    else
      @setPageModels()
      options.success(@) if options.success?
      return @

  next: (callbacks)-> @goTo(@currentPage + 1, callbacks)
  prev: (callbacks)-> @goTo(@currentPage - 1, callbacks)

  refresh: -> 
    @goTo(@currentPage, fetch: false) 

    