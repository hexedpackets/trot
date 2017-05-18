# trot
[![Hex.pm](https://img.shields.io/hexpm/v/trot.svg)](https://hex.pm/packages/trot) [![Build Status](https://travis-ci.org/hexedpackets/trot.svg?branch=master)](https://travis-ci.org/hexedpackets/trot) [![Inline docs](http://inch-ci.org/github/hexedpackets/trot.svg)](http://inch-ci.org/github/hexedpackets/trot)

Trot is an Elixir web micro-framework based on Plug and Cowboy. The goal of Trot is to make common patterns in Plug easier to use, particularly when writing APIs, without sacrificing flexibility.

## Usage
Add Trot as a dependency to your `mix.exs` file and update your applications list to include it.

```Elixir
    defp deps do
      [{:trot, github: "hexedpackets/trot"}]
    end

    def application do
      [applications: [:trot]]
    end
```

The following configuration options are supported by the server:

`config :trot, :port, 4000`: port to listen on for incoming HTTP requests. Defaults to "4000".

`config :trot, :router, MyApp.Router`: module to route requests to. Defaults to "Trot.NotFound".

`config :trot, :heartbeat, "/heartbeat"`: path to setup a heartbeat route. This will always return 200 with a body of
"OK". Defaults to "/heartbeat". NOTE: This value will only have an effect when PlugHeartbeat is part of the plug list.

`config :trot, :pre_routing, ["Elixir.CustomPlug": [plug_arg: value]]`: Plugs that should be run before routing a request along with their arguments. Defaults to setting up "Trot.LiveReload", "Plug.Logger", and "PlugHeartbeat" in that order.

`config :trot, :post_routing, ["Elixir.CustomPlug": [plug_arg: value]]`: Plugs that should be run after routing a request along with their arguments. Defaults to "[]".

Finally, put `use Trot.Router` to the top of your module. This will add route macros and setup the plug pipeline at compile time.


## Getting started
To get a basic devserver up and running, make sure you add a Router module in the config as described above, and then simply
```
$ mix trot.server
```

_Note: You can also start the server as well as an iex shell by running `iex -S mix`_

## Routes
Routes are specified using one of the HTTP method macros: `get/3`, `post/3`, `put/3`, `patch/3`, `delete/3`, `options/3`. The first argument is a the path to route to, the second (optional) argument is a keyword list of any options to match against,  and the last argument is the block of code to execute. Examples are below.

If `@path_root` is specified, it will be prefixed to all routes in that module.

Routes can be setup in different modules and imported into the main router with the `import_routes/1` macro, which takes a module name as the only argument. Note that ordering matters as normal Elixir pattern matching rules apply to imported routes.

A default 404 response can be enabled by putting `import_routes Trot.NotFound` or `use Trot.NotFound` at the end of the module.

### Responses
All of the following are valid return values from handlers and will be parsed into full HTTP responses:
- String of response body
- Status code, either numeric or an atom from `Plug.Conn.Status`
- `{code, body}`
- `{code, body, headers}`
- JSONable object
- `{code, object}`
- `{code, object, headers}`
- `{:redirect, location}`
- `{:badrpc, error}`
- `%Plug.Conn{}`

### Example router application

```Elixir
    defmodule SoLoMoApp.Router do
      use Trot.Router

      # Setup a static route to priv/static/assets
      static "/css", "assets"

      # Returns an empty body with a status code of 400
      get "/bad" do
        :bad_request
      end

      # Sets the status code to 200 with a text body
      get "/text" do
        "Thank you for your question."
      end

      # Redirect the incoming request
      get "/text/body", headers: ["x-text-type": "question"] do
        {:redirect, "/text"}
      end

      # Sets the status code to 201 with a text body
      get "/text/body" do
        {201, "optimal tip-to-tip efficiency"}
      end

      # Sets status code to 200 with a JSON-encoded body
      get "/json" do
        %{"hyper" => "social"}
      end

      # Pattern match part of the path into a variable
      get "/presenter/:name" do
        "The presenter is #{name}"
      end

      import_routes Trot.NotFound
    end
```

## Templating
To add templating in a router, add `use Trot.Template` and set `@template_root` to the top-level directory containing your templates. By default, `@template_root` is "priv/templates/".

Trot can be used to render EEx templates (the default engine include with Elixir), HAML templates through [Calliope](https://github.com/nurugger07/calliope), or a combination of both. When the application is compiled a `render_template/2` function is generated for every template under `@template_root`. `render_template/2` expects the name of the template relative to `@template_root` as the first argument and a keyword list of variables to assign as the second argument.

When `MIX_ENV=prod` all of templates are loaded and pre-compiled for faster rendering.

### Example app using templates

```Elixir
    defmodule PiedPiper do
      use Trot.Router
      use Trot.Template
      @template_root "priv/templates/root"

      get "/compression/pied_piper" do
        render_template("compression_results.html.eex", [weissman_score: 5.2])
      end

      get "/compression/nucleus" do
        render_template("compression_results.html.haml", [weissman_score: 2.89])
      end
    end

    # compression_results.html.eex
    <html><body>Pied piper has a Weissman Score of <%= @weissman_score %></body></html>

    # compression_results.html.haml
    %html
      %body Nucleaus has a Weissman Score of <%= @weissman_score %>
```

## Additional plugs
The plug/2 macro is available within a Trot router, allowing any plug to be inserted into the pipeline. Anything after `Trot.Router` will likely have a closed connection, so most uses cases will involve pulling in `Plug.Builder` first.

### Example plug before Trot

```Elixir
    defmodule SoLoMoApp.Router do
      use Plug.Builder
      plug Plug.RequestId

      use Trot.Router
      get "/hello", do: "hello"
    end
```

## API versioning
Adding `use Trot.Versioning` to your module will enable API version parsing and pattern matching. The first part of the path for all requests in the module is assumed to be the version. It is parsed into the `conn[:assigns]` dictionary, making it easy to access. Routes can also be configured to only match a particular version.

### Example versioned app

```Elixir
    defmodule Nucleus do
      use Trot.Router
      use Trot.Versioning

      get "/version" do
        conn.assigns[:version]
      end

      get "/current", version: "v1" do
        :ok
      end

      get "/current" do
        :bad_request
      end
    end
```

In the above example, "/v1/version" will return "v1" as the response body. A request to "/v1/current" will return a 200 but "/v2/current" will return a 400.
