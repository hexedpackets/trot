# 0.7.0 July 25, 2018
- Set the Content-Type response header to application/json automatically when encoding JSON responses.
- Fix for handling of the path "/" in Elixir 1.6
- Add `Plug.Parsers` to the default pre-routing Plug list.

# 0.6.1 April 4, 2018
- Fix deprecation warnings for `String.strip/1` and `String.lstrip/2`.
- Update live reload Plug for compatability with Elixir 1.6.

# 0.6.0 July 20, 2017
- Support for settting custom plugs to pass requests through before or after routing
- New plug, Trot.AuthCheck, for requiring authorization on a select set of routes.
- Update Elixir to 1.4
- Update dependancies
- Replace deprecated `Behaviour` module with `@callback` attributes

# 0.5.3 October 1, 2015
- Update plug_heartbeat dependency to remove usage of deprecated function in Plug

# 0.5.2 June 14, 2015
- Added VERSION file to hex package

# 0.5.1 - June 14, 2015
- Compatability fixed with Plug v0.13.0
- Added `plug_heartbeat` to the list of applications for exrm releases
- Ensure redirects are sent with lowercase headers
- Convert cowboy port to an integer when starting up

# 0.5.0 - June 2, 2015
- Start Cowboy automatically based on configured values in the application
- Support parsing RPC errors into HTTP responses
- Added default route for `/heartbeat`
- Added live code reloading in dev

# 0.4.0 - May 26, 2015
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
