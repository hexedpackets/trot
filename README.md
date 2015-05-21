# trot

Trot is an Elixir web micro-framework based on Plug and Cowboy. The goal of Trot is to make common patterns in Plug easier to use, particularly when writing APIs, without sacrificing flexibility.


## Responses
All of the following are valid return values from handlers and will be parsed into full HTTP responses:
- String of response body
- Status code, either numeric or an atom from `Plug.Conn.Status`
- `{code, body}`
- JSONable object
- `{code, object}`
- `{:redirect, location}`
- `%Plug.Conn{}`


## Templates
Some conviences are provided for using EEx, the default templating engine include with Elixir. When the application is compiled all of templates under a given path are loaded and compiled for quicker rendering. A `render/2` function is generated for every template under the module attribute `@template_root`. By default, `@template_root` is "templates/".


### Example app using templates:

    defmodule PiedPiper do
      use Trot.Router
      use Trot.Template
      @template_root "templates/root"

      get "/compression" do
        render("compression_results.html.eex", [weissman_score: 5.2])
      end
    end


### Example router application
    defmodule SoLoMoApp.Router do
      use Trot.Router

      # Sets status code to 200 with an empty body
      get "/" do
        200
      end

      # Returns an empty body with a status code of 404
      get "/bad" do
        :bad_request
      end

      # Sets the status code to 200 with a text body
      get "/text" do
        "Thank you for your question."
      end

      # Sets the status code to 201 with a text body
      get "/text/body" do
        {201, "Thank you for your question."}
      end

      # Sets status code to 200 with a JSON-encoded body
      get "/json" do
        %{"hyper" => "social"}
      end

      # Sets the status code to 201 with a JSON-encoded body
      get "/json/code" do
        {201, %{"hyper" => "social"}}
      end

      # Set the response manually as when using Plug directly
      get "/conn" do
        send_resp(conn, 200, "optimal tip-to-tip efficiency")
      end

      # Pattern match part of the path into a variable
      get "/presenter/:name" do
        "The presenter is #{name}"
      end

      # Redirect the incoming request
      get "/redirect" do
        {:redirect, "/text/body"}
      end
    end
