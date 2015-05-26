# 0.4.0 - UNRELEASED
- Support for API versioning with pattern patching against versions
- Made connection handling for unknown routes optional. The old behavior can be re-enabled by adding `use Trot.NotFound` to the end of a routing module.
- Added `import_routes/1` as a new macro to help chain router modules
- Allow headers to be passed as part of a route's returned tuple and parse them into the HTTP response
- Added the ability to route requests based on HTTP request headers

# 0.3.0 - May 23, 2015
- Support for template rendering using EEx and/or HAML
- Add a default root for static routes of priv/static
- Support setting the module attribute @path_root as a prefix to route paths

# 0.2.1 - May 20, 2015
- Fixed sending response of {atom, text} to resolve the atom to a status code

# 0.2.0 - May 20, 2015
- Support for redirection through a macro and normal return values
- Support for static routes through a macro
- End the plug pipeline with a `not_found` function
