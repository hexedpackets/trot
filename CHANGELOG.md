# 0.3.0 - UNRELEASED
- Support for template rendering using EEx and/or HAML
- Add a default root for static routes of priv/static
- Support setting the module attribute @path_root as a prefix to route paths

# 0.2.1 - May 20, 2015
- Fixed sending response of {atom, text} to resolve the atom to a status code

# 0.2.0 - May 20, 2015
- Support for redirection through a macro and normal return values
- Support for static routes through a macro
- End the plug pipeline with a `not_found` function
