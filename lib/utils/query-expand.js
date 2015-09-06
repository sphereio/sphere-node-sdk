/**
 * Utils `query-expand` module.
 * @module utils/queryExpand
 */

/**
 * Set the
 * [ExpansionPath](http://dev.sphere.io/http-api.html#reference-expansion)
 * used for expanding a
 * [Reference](http://dev.sphere.io/http-api-types.html#reference)
 * of a resource.
 *
 * @param  {string} expansionPath - The expand path expression.
 * @throws If `expansionPath` is missing.
 * @return {Object} The instance of the service, can be chained.
 */
export function expand (expansionPath) {
  if (!expansionPath)
    throw new Error('Parameter `expansionPath` is missing')

  if (expansionPath) {
    const encodedPath = encodeURIComponent(expansionPath)
    // Note: this goes to base `params`, not `params.query`
    // to be compatible with search.
    this.params.expand.push(encodedPath)
  }
  return this
}