_ = require 'underscore'
_.mixin require 'underscore-mixins'
Promise = require 'bluebird'
{TaskQueue} = require '../../../lib/main'
ProductProjectionService = require '../../../lib/services/product-projections'

###*
 * Describe service specific implementations
###
describe 'ProductProjectionService', ->

  beforeEach ->
    @restMock =
      config: {}
      GET: (endpoint, callback) ->
      POST: -> (endpoint, payload, callback) ->
      PUT: ->
      DELETE: -> (endpoint, callback) ->
      PAGED: -> (endpoint, callback) ->
      _preRequest: ->
      _doRequest: ->
    @task = new TaskQueue
    @service = new ProductProjectionService
      _rest: @restMock
      _task: @task
      _stats:
        includeHeaders: false

  it 'should reset default params', ->
    expect(@service._params).toEqual
      encoded: ['where', 'expand', 'sort', 'filter', 'filter.query', 'filter.facets', 'facets', 'searchKeywords']
      plain: ['perPage', 'page', 'staged', 'fuzzy', 'priceCurrency', 'priceCountry', 'priceCustomerGroup', 'priceChannel']
      query:
        where: []
        operator: 'and'
        sort: []
        expand: []
        staged: false
        fuzzy: false
        filter: []
        filterByQuery: []
        filterByFacets: []
        facet: []
        searchKeywords: []
        priceCurrency: false
        priceCountry: false
        priceCustomerGroup: false
        priceChannel: false

  _.each [
    ['staged', [false]]
    ['fuzzy', [false]]
    ['text', ['foo', 'de']]
    ['filter', ['foo:bar']]
    ['filterByQuery', ['foo:bar']]
    ['filterByFacets', ['foo:bar']]
    ['facet', ['foo:bar']]
    ['priceCurrency', ['abcd']]
  ], (f) ->
    it "should chain search function '#{f[0]}'", ->
      clazz = @service[f[0]].apply(@service, _.toArray(f[1]))
      expect(clazz).toEqual @service

      promise = @service[f[0]].apply(@service, _.toArray(f[1])).search()
      expect(promise.isPending()).toBe true

  it 'should query for staged', ->
    expect(@service.staged()._queryString()).toBe 'staged=true'

  it 'should query for priceCurrency', ->
    expect(@service.priceCurrency('abcd')._queryString()).toBe 'priceCurrency=abcd'

  it 'should throw when querying price selection without priceCurrency', ->
    expect(=> @service.priceChannel('abcd')._queryString())
      .toThrow(new Error("Field priceCurrency is required to enable price selection. Read more here http://dev.commercetools.com/http-api-projects-products.html#price-selection"))

  it 'should query for priceCountry', ->
    expect(@service.priceCurrency('abcd').priceCountry('abcd')._queryString()).toBe 'priceCurrency=abcd&priceCountry=abcd'

  it 'should query for priceCustomerGroup', ->
    expect(@service.priceCurrency('abcd').priceCustomerGroup('abcd')._queryString()).toBe 'priceCurrency=abcd&priceCustomerGroup=abcd'

  it 'should query for priceChannel', ->
    expect(@service.priceCurrency('abcd').priceChannel('abcd')._queryString()).toBe 'priceCurrency=abcd&priceChannel=abcd'

  it 'should query for fuzzy', ->
    expect(@service.fuzzy()._queryString()).toBe 'fuzzy=true'

  it 'should query for published', ->
    expect(@service.staged(false)._queryString()).toBe ''

  it 'should query for text', ->
    expect(@service.text('foo', 'de')._queryString()).toBe 'text.de=foo'

  it 'should encode query for text', ->
    expect(@service.text('äöüß', 'de')._queryString()).toBe "text.de=#{encodeURIComponent('äöüß')}"

  it 'should throw if lang is not defined', ->
    expect(=> @service.text('foo')).toThrow new Error 'Language parameter is required for searching'

  it 'should query for filter', ->
    expect(@service.filter('foo:bar')._queryString()).toBe 'filter=foo%3Abar'

  it 'should query for filter.query', ->
    expect(@service.filterByQuery('foo:bar')._queryString()).toBe 'filter.query=foo%3Abar'

  it 'should query for filter.facets', ->
    expect(@service.filterByFacets('foo:bar')._queryString()).toBe 'filter.facets=foo%3Abar'

  it 'should query for facet', ->
    expect(@service.facet('foo:bar')._queryString()).toBe 'facet=foo%3Abar'

  it 'should build search query string', ->
    queryString = @service
      .page 3
      .perPage 25
      .sort('createdAt')
      .text('foo', 'de')
      .filter('foo:bar')
      .filterByQuery('foo:bar')
      .filterByFacets('foo:bar')
      .facet('foo:bar')
      .priceCurrency('EUR')
      .priceCountry('GB')
      .priceCustomerGroup('UUID1')
      .priceChannel('UUID2')
      ._queryString()

    priceSelectionQuery = 'priceCurrency=EUR&priceCountry=GB&priceCustomerGroup=UUID1&priceChannel=UUID2'
    expectedQuery = 'limit=25&offset=50&sort=createdAt%20asc&text.de=foo&filter=foo%3Abar&filter.query=foo%3Abar&filter.facets=foo%3Abar&facet=foo%3Abar'
    expect(queryString).toBe "#{expectedQuery}&#{priceSelectionQuery}"

  it "should reset search custom params after creating a promise", ->
    _service = @service
      .page 3
      .perPage 25
      .sort('createdAt')
      .staged()
      .fuzzy()
      .text('foo', 'de')
      .filter('filter1:bar1')
      .filter('filter2:bar2')
      .filterByQuery('filterQuery1:bar1')
      .filterByQuery('filterQuery2:bar2')
      .filterByFacets('filterFacets1:bar1')
      .filterByFacets('filterFacets2:bar2')
      .facet('facet1:bar1')
      .facet('facet2:bar2')
    expect(@service._params).toEqual
      encoded: ['where', 'expand', 'sort', 'filter', 'filter.query', 'filter.facets', 'facets', 'searchKeywords']
      plain: ['perPage', 'page', 'staged', 'fuzzy', 'priceCurrency', 'priceCountry', 'priceCustomerGroup', 'priceChannel']
      query:
        where: []
        operator: 'and'
        sort: [encodeURIComponent('createdAt asc')]
        expand: []
        page: 3
        perPage: 25
        staged: true
        fuzzy: true
        text:
          lang: 'de'
          value: 'foo'
        priceCurrency: false
        priceCountry: false
        priceCustomerGroup: false
        priceChannel: false
        filter: [encodeURIComponent('filter1:bar1'), encodeURIComponent('filter2:bar2')]
        filterByQuery: [encodeURIComponent('filterQuery1:bar1'), encodeURIComponent('filterQuery2:bar2')]
        filterByFacets: [encodeURIComponent('filterFacets1:bar1'), encodeURIComponent('filterFacets2:bar2')]
        facet: [encodeURIComponent('facet1:bar1'), encodeURIComponent('facet2:bar2')]
        searchKeywords: []
    _service.search()
    expect(@service._params).toEqual
      encoded: ['where', 'expand', 'sort', 'filter', 'filter.query', 'filter.facets', 'facets', 'searchKeywords']
      plain: ['perPage', 'page', 'staged', 'fuzzy', 'priceCurrency', 'priceCountry', 'priceCustomerGroup', 'priceChannel']
      query:
        where: []
        operator: 'and'
        sort: []
        expand: []
        staged: false
        fuzzy: false
        filter: []
        filterByQuery: []
        filterByFacets: []
        facet: []
        searchKeywords: []
        priceCurrency: false
        priceCountry: false
        priceCustomerGroup: false
        priceChannel: false

  it 'should set queryString, if given', ->
    @service.byQueryString('where=name(en = "Foo")&limit=10&staged=true&sort=name asc&expand=foo.bar1&expand=foo.bar2')
    expect(@service._params.queryString).toEqual 'where=name(en%20%3D%20%22Foo%22)&limit=10&staged=true&sort=name%20asc&expand=foo.bar1&expand=foo.bar2'

    @service.byQueryString('filter=variants.price.centAmount:100&filter=variants.attributes.foo:bar&staged=true&limit=100&offset=2')
    expect(@service._params.queryString).toEqual 'filter=variants.price.centAmount%3A100&filter=variants.attributes.foo%3Abar&staged=true&limit=100&offset=2'

  it 'should set queryString, if given (already encoding)', ->
    @service.byQueryString('where=name(en%20%3D%20%22Foo%22)&limit=10&staged=true&sort=name%20asc&expand=foo.bar1&expand=foo.bar2', true)
    expect(@service._params.queryString).toEqual 'where=name(en%20%3D%20%22Foo%22)&limit=10&staged=true&sort=name%20asc&expand=foo.bar1&expand=foo.bar2'

    @service.byQueryString('filter=variants.price.centAmount%3A100&filter=variants.attributes.foo%3Abar&staged=true&limit=100&offset=2', true)
    expect(@service._params.queryString).toEqual 'filter=variants.price.centAmount%3A100&filter=variants.attributes.foo%3Abar&staged=true&limit=100&offset=2'

  it 'should analyze and store params from queryString', ->
    @service.byQueryString('where=productType(id="123")&perPage=100&staged=true&fuzzy=true&priceCurrency=EUR&priceCountry=GB&priceCustomerGroup=UUID1&priceChannel=UUID2')
    expect(@service._params).toEqual
      encoded: ['where', 'expand', 'sort', 'filter', 'filter.query', 'filter.facets', 'facets', 'searchKeywords']
      plain: ['perPage', 'page', 'staged', 'fuzzy', 'priceCurrency', 'priceCountry', 'priceCustomerGroup', 'priceChannel']
      query:
        where: ['productType(id%3D%22123%22)']
        operator: 'and'
        sort: []
        expand: []
        filter: []
        filterByQuery: []
        filterByFacets: []
        facet: []
        searchKeywords: []
        perPage: 100
        staged: 'true'
        fuzzy: 'true'
        priceCurrency: 'EUR'
        priceCountry: 'GB'
        priceCustomerGroup: 'UUID1'
        priceChannel: 'UUID2'
      queryString: 'where=productType(id%3D%22123%22)&staged=true&fuzzy=true&priceCurrency=EUR&priceCountry=GB&priceCustomerGroup=UUID1&priceChannel=UUID2&limit=100'

  it 'should support also API limit parameter', ->
    @service.byQueryString('where=productType(id="123")&limit=100&staged=true&fuzzy=true&priceCurrency=EUR&priceCountry=GB&priceCustomerGroup=UUID1&priceChannel=UUID2')
    expect(@service._params.queryString).toEqual 'where=productType(id%3D%22123%22)&limit=100&staged=true&fuzzy=true&priceCurrency=EUR&priceCountry=GB&priceCustomerGroup=UUID1&priceChannel=UUID2'

  describe ':: priceSelection required params', ->
    _.each [
      'priceCurrency'
      'priceCountry'
      'priceCustomerGroup'
      'priceChannel'
    ], (paramName) ->
      it "should throw if param '#{paramName}' is not provided", ->
        # Uppercase first letter
        expectedError = "#{paramName.charAt(0).toUpperCase() + paramName.slice(1)} parameter is required"
        expect(=> @service[paramName]()).toThrow new Error expectedError

  describe ':: search', ->

    it 'should call \'fetch\' after setting search endpoint', ->
      spyOn(@service, 'fetch')
      @service.text('foo', 'de').filter('foo:bar').search()
      expect(@service.fetch).toHaveBeenCalled()
      expect(@service._currentEndpoint).toBe '/product-projections/search'

  describe ':: asSearch', ->

    it 'should change the endpoint and return itself', ->
      s = @service.asSearch()
      expect(@service._currentEndpoint).toBe '/product-projections/search'
      expect(s).toBe @service

  describe ':: suggest', ->

    it 'should call \'fetch\' after setting suggest endpoint', ->
      spyOn(@service, 'fetch')
      @service.searchKeywords('foo', 'de').suggest()
      expect(@service.fetch).toHaveBeenCalled()
      expect(@service._currentEndpoint).toBe '/product-projections/suggest'

    it 'should build query for multiple search keywords', ->
      spyOn(@service, 'fetch')
      @service
      .searchKeywords('foo1', 'de')
      .searchKeywords('foo2', 'en')
      .searchKeywords('äöüß', 'it')
      .suggest()
      expect(@service._queryString()).toBe "searchKeywords.de=foo1&searchKeywords.en=foo2&searchKeywords.it=#{encodeURIComponent('äöüß')}"

    it 'should throw if text or lang are not defined', ->
      expect(=> @service.searchKeywords()).toThrow new Error 'Suggestion text parameter is required for searching for a suggestion'
      expect(=> @service.searchKeywords('foo')).toThrow new Error 'Language parameter is required for searching for a suggestion'

  describe ':: fetch', ->

    it 'should fetch all with default sorting', (done) ->
      spyOn(@restMock, 'PAGED').andCallFake (endpoint, callback) -> callback(null, {statusCode: 200}, {total: 1, results: []})
      @service.where('foo=bar').staged(true).all().fetch()
      .then (result) =>
        expect(@restMock.PAGED).toHaveBeenCalledWith "/product-projections?where=foo%3Dbar&sort=id%20asc&staged=true", jasmine.any(Function)
        done()
      .catch (err) -> done(_.prettify err)

  describe ':: process', ->

    it 'should call each page with the same query (default sorting)', (done) ->
      offset = -20
      count = 20
      spyOn(@restMock, 'GET').andCallFake (endpoint, callback) ->
        offset += 20
        callback(null, {statusCode: 200}, {
          # total: 50
          count: if offset is 40 then 10 else count
          offset: offset
          results: _.map (if offset is 40 then [1..10] else [1..20]), (i) -> {id: "id_#{i}", endpoint}

        })
      fn = (payload) ->
        Promise.resolve payload.body.results[0]
      @service.where('foo=bar').whereOperator('or').staged(true).process(fn)
      .then (result) ->
        expect(_.size result).toBe 3
        expect(result[0].endpoint).toMatch /\?sort=id%20asc&where=foo%3Dbar&staged=true&withTotal=false$/
        expect(result[1].endpoint).toMatch /\?sort=id%20asc&where=foo%3Dbar&staged=true&withTotal=false&where=id%20%3E%20%22id_20%22$/
        expect(result[2].endpoint).toMatch /\?sort=id%20asc&where=foo%3Dbar&staged=true&withTotal=false&where=id%20%3E%20%22id_20%22$/
        done()
      .catch (err) -> done(_.prettify err)

    it 'should call each page with the same query (given sorting)', (done) ->
      # create a list of 80 products
      products = [1..80].map (i) -> {id: "id_#{i}"}
      perPage = 30
      offset = -perPage

      spyOn(@restMock, 'GET').andCallFake (endpoint, callback) ->
        offset += perPage
        # get subset of 30 products starting with a given offset
        results = products.slice(offset, offset + perPage)
        callback(null, {statusCode: 200}, {
          total: products.length
          count: results.length
          offset: offset
          results: results
        })

      @service
        .staged(true)
        .perPage(perPage)
        .sort('name', false)
        .where('foo=bar')
        .where('hello=world')
        .whereOperator('or')
        .process -> Promise.resolve()
        .then =>
          expect(@restMock.GET.calls.length).toEqual 3
          expect(@restMock.GET.calls[0].args[0]).toMatch /\?sort=id%20asc&where=foo%3Dbar%20or%20hello%3Dworld&limit=30&sort=name%20desc&staged=true&withTotal=false$/
          expect(@restMock.GET.calls[1].args[0]).toMatch /\?sort=id%20asc&where=foo%3Dbar%20or%20hello%3Dworld&limit=30&sort=name%20desc&staged=true&withTotal=false&where=id%20%3E%20%22id_30%22$/
          expect(@restMock.GET.calls[2].args[0]).toMatch /\?sort=id%20asc&where=foo%3Dbar%20or%20hello%3Dworld&limit=30&sort=name%20desc&staged=true&withTotal=false&where=id%20%3E%20%22id_60%22$/
          done()
        .catch (err) -> done(_.prettify err)

    it 'should call each page with the same query when using byQueryString', (done) ->
      # create a list of 80 products
      products = [1..80].map (i) -> {id: "id_#{i}"}
      perPage = 30
      offset = -perPage

      spyOn(@restMock, 'GET').andCallFake (endpoint, callback) ->
        offset += perPage
        # get subset of 30 products starting with a given offset
        results = products.slice(offset, offset + perPage)
        callback(null, {statusCode: 200}, {
          total: products.length
          count: results.length
          offset: offset
          results: results
        })

      @service
        .byQueryString('where=foo=bar&staged=true&limit=30')
        .process -> Promise.resolve()
        .then =>
          # sdk should use custom queryString
          expect(@restMock.GET.calls.length).toEqual 3
          expect(@restMock.GET.calls[0].args[0]).toMatch /\?sort=id%20asc&where=foo%3Dbar&staged=true&limit=30&withTotal=false$/
          expect(@restMock.GET.calls[1].args[0]).toMatch /\?sort=id%20asc&where=foo%3Dbar&staged=true&limit=30&withTotal=false&where=id%20%3E%20%22id_30%22$/
          expect(@restMock.GET.calls[2].args[0]).toMatch /\?sort=id%20asc&where=foo%3Dbar&staged=true&limit=30&withTotal=false&where=id%20%3E%20%22id_60%22$/
          done()
        .catch (err) -> done(_.prettify err)
