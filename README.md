# SimpleHttp [![Travis](https://travis-ci.org/alexandrubagu/simplehttp.svg)](https://travis-ci.org/alexandrubagu/simplehttp)

## Hex Installation 

  1. Add `simplehttp` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:simplehttp, "~> 0.1.0"}]
    end
    ```

  2. Ensure `simplehttp` is started before your application:

    ```elixir
    def application do
      [applications: [:simplehttp]]
    end
    ```

## Usage

*Note*: You can load HTTPotion into the Elixir REPL by executing this command from the root of your project:

```elixir
$ iex -S mix
```

*Note* Before you start to make a request you need to start inet, this can be do calling this function:

```elixir
SimpleHttp.start
```

Some basic examples:

```elixir
    {:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1"

```

```elixir
    {:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1", [
      query_params: [
        postId: 1
      ]
    ]
```

```elixir
    {:ok, response} = SimpleHttp.post "http://jsonplaceholder.typicode.com/posts", [
      body: "{\"name\":\"foo.example.com\"}",
      content_type: "application/json",
      timeout: 1000,
      connect_timeout: 1000
    ]
```

```elixir
    {:ok, response} = SimpleHttp.post "http://jsonplaceholder.typicode.com/posts", [
      params: [
        title: "title is present here",
        message: "hello world!"
      ],
      content_type: "application/x-www-form-urlencoded",
      timeout: 1000,
      connect_timeout: 1000
    ]
```
