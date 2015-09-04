/**
 * Utils `default-params` module.
 * @module utils/defaultParams
 */

/**
 * Return the default parameters for building a query string.
 *
 * @return {Object}
 */
export function getDefaultQueryParams () {
  return {
    id: null,
    pagination: {
      page: null,
      perPage: null,
      sort: []
    },
    query: {
      expand: [],
      operator: 'and',
      where: []
    }
  }
}

/**
 * Return the default parameters for building a query search string.
 *
 * @return {Object}
 */
export function getDefaultSearchParams () {
  return {
    staged: true,
    pagination: {
      page: null,
      perPage: null,
      sort: []
    },
    search: {
      facet: [],
      filter: [],
      filterByQuery: [],
      filterByFacets: [],
      text: null
    }
  }
}

export function setDefaultParams (type, params) {
  if (type === 'product-projections-search') {
    params.staged = getDefaultSearchParams().staged
    params.pagination = getDefaultSearchParams().pagination
    params.search = getDefaultSearchParams().search
    return
  }

  if (type === 'product-projections')
    params.staged = true

  params.id = getDefaultQueryParams().id,
  params.pagination = getDefaultQueryParams().pagination
  params.query = getDefaultQueryParams().query
}