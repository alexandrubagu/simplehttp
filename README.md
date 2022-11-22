# SimpleHttp [![Travis](https://travis-ci.org/alexandrubagu/simplehttp.svg)](https://travis-ci.org/alexandrubagu/simplehttp) [![Hex.pm](https://img.shields.io/hexpm/v/simplehttp.svg?maxAge=2592000)](https://hex.pm/packages/simplehttp) [![Hex.pm](https://img.shields.io/hexpm/dt/simplehttp.svg?maxAge=2592000)](https://hex.pm/packages/simplehttp) [![Hex.pm](https://img.shields.io/hexpm/l/simplehttp.svg?maxAge=2592000)](https://hex.pm/packages/simplehttp) [![Coverage Status](https://coveralls.io/repos/github/alexandrubagu/simplehttp/badge.svg?branch=master)](https://coveralls.io/github/alexandrubagu/simplehttp?branch=master)

## Unlike other projects / libraries, SimpleHttp doesn't have other dependencies

<table>
  <tbody>
    <tr>
      <th>SimpleHttp</th>
      <th> <a href="https://github.com/myfreeweb/httpotion">myfreeweb/httpotion</a> </th>
      <th> <a href="https://github.com/edgurgel/httpoison">edgurgel/httpoison</a> </th>
    </tr>
    <tr>
      <td valign="top">
	<pre class="vicinity rich-diff-level-zero">
	   <code class="rich-diff-level-one">
$ mix app.tree      

simplehttp
├── elixir
└── logger
    └── elixir
	   </code>
        </pre> 
      </td>
      <td valign="top">
	<pre class="vicinity rich-diff-level-zero">
	   <code class="rich-diff-level-one">
$ mix app.tree      

httpotion
├── elixir
├── ssl
│   ├── crypto
│   └── public_key
│       ├── asn1
│       └── crypto
└── ibrowse
	   </code>
        </pre> 
      </td>
      <td valign="top">
	<pre class="vicinity rich-diff-level-zero">
	   <code class="rich-diff-level-one">
$ mix app.tree      

httpoison
├── elixir
└── hackney
    ├── crypto
    ├── asn1
    ├── public_key
    │   ├── asn1
    │   └── crypto
    ├── ssl
    │   ├── crypto
    │   └── public_key
    ├── idna
    ├── mimerl
    ├── certifi
    ├── ssl_verify_fun
    │   └── ssl
    └── metrics
	   </code>
        </pre> 
      </td>
    </tr>
  </tbody>
</table>

## Hex Installation 

  1. Add `simplehttp` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:simplehttp, "~> 0.5.1"}]
  end
  ```


## Usage

*Note*:You can load SimpleHttp into the Elixir REPL by executing this command from the root of your project:

```elixir
$ iex -S mix
```

Simple GET Request
```elixir
{:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1"

IO.inspect response 
{:ok,
%SimpleHttp.Response{
  body: "{\n  \"userId\": 1,\n  \"id\": 1,\n  \"title\": \"sunt aut facere repellat provident occaecati excepturi optio reprehenderit\",\n  \"body\": \"quia et suscipit\\nsuscipit recusandae consequuntur expedita et cum\\nreprehenderit molestiae ut ut quas totam\\nnostrum rerum est autem sunt rem eveniet architecto\"\n}",
  headers: [
    {'cache-control', 'public, max-age=14400'},
    {'connection', 'keep-alive'},
    {'date', 'Mon, 22 Oct 2018 07:02:48 GMT'},
    {'pragma', 'no-cache'},
    {'via', '1.1 vegur'},
    {'etag', 'W/"124-yiKdLzqO5gfBrJFrcdJ8Yq0LGnU"'},
    {'server', 'cloudflare'},
    {'vary', 'Origin, Accept-Encoding'},
    {'content-length', '292'},
    {'content-type', 'application/json; charset=utf-8'},
    {'expires', 'Mon, 22 Oct 2018 11:02:48 GMT'},
    {'set-cookie',
      '__cfduid=de34235eb1c3436a238889924c15be9671540191768; expires=Tue, 22-Oct-19 07:02:48 GMT; path=/; domain=.typicode.com; HttpOnly'},
    {'x-powered-by', 'Express'},
    {'access-control-allow-credentials', 'true'},
    {'x-content-type-options', 'nosniff'},
    {'cf-cache-status', 'HIT'},
    {'cf-ray', '46da19b6d5f87ea0-BUD'}
  ],
  status: 200
}}
```

GET Request with query params
```elixir
{:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1", [
  query_params: [
    postId: 1
  ]
]
```

POST with JSON
```elixir
{:ok, response} = SimpleHttp.post "http://jsonplaceholder.typicode.com/posts", [
  body: "{\"name\":\"foo.example.com\"}",
  headers: %{
    "Content-Type" => "application/x-www-form-urlencoded",
    "Authorization" => "Bearer hash",
    "X-Customer" => "123"
  },
  timeout: 1000,
  connect_timeout: 1000
]
```

POST with params
```elixir
{:ok, response} = SimpleHttp.post "http://jsonplaceholder.typicode.com/posts", [
  params: [
    title: "title is present here",
    message: "hello world!"
  ],
  headers: %{
    "Content-Type" => "application/x-www-form-urlencoded",
    "Authorization" => "Bearer hash",
    "X-Customer" => "123"
  },
  timeout: 1000,
  connect_timeout: 1000
]
```

