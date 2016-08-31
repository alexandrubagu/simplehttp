# SimpleHttp [![Travis](https://travis-ci.org/alexandrubagu/simplehttp.svg)](https://travis-ci.org/alexandrubagu/simplehttp)

## Description

####**Unlike other projects / libraries, SimpleHttp doesn't have other dependencies**

[alexandrubagu/simplehttp]https://github.com/alexandrubagu/simplehttpn) 
```
$ mix app.tree

simplehttp
├── elixir
└── logger
    └── elixir
```

###For example:
1. [myfreeweb/httpotion](https://github.com/myfreeweb/httpotion) 
```
$ mix app.tree                          

httpotion
├── elixir
├── ssl
│   ├── crypto
│   └── public_key
│       ├── asn1
│       └── crypto
└── ibrowse
```

2. [edgurgel/httpoison](https://github.com/edgurgel/httpoison)

**BUILD FAILED**

```
Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:4:4] [async-threads:10] [kernel-poll:false]

===> Compiling ssl_verify_fun
===> Compiling src/ssl_verify_hostname.erl failed
src/ssl_verify_hostname.erl:8: can't find include lib "public_key/include/public_key.hrl"
src/ssl_verify_hostname.erl:102: undefined macro 'id-ce-subjectAltName'

src/ssl_verify_hostname.erl:79: record 'AttributeTypeAndValue' undefined
src/ssl_verify_hostname.erl:81: variable 'CN' is unbound
src/ssl_verify_hostname.erl:94: variable 'ExtId' is unbound
src/ssl_verify_hostname.erl:94: record 'Extension' undefined
src/ssl_verify_hostname.erl:242: record 'OTPTBSCertificate' undefined
src/ssl_verify_hostname.erl:255: record 'OTPCertificate' undefined
src/ssl_verify_hostname.erl:257: function extract_dns_names/1 undefined

src/ssl_verify_hostname.erl:87: Warning: function extensions_list/1 is unused
src/ssl_verify_hostname.erl:93: Warning: function select_extension/2 is unused
src/ssl_verify_hostname.erl:110: Warning: function extract_dns_names_from_alt_names/2 is unused
```


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

*Note* **Before you start to make a request you need to start inet, this can be do calling this function:**

```elixir
SimpleHttp.start
```

Simple GET Request
```elixir
    {:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1"

    IO.inspect response.status 
    ~s"""
        {'HTTP/1.1', 200, 'OK'}
    """

    IO.inspect response.headers
    ~s"""
   		[{'cache-control', 'public, max-age=14400'}, {'connection', 'keep-alive'},
		 {'content-length', '292'}, {'content-type', 'application/json; charset=utf-8'},
		 {'expires', 'Wed, 31 Aug 2016 22:15:00 GMT'},
		 {'set-cookie',
		  '__cfduid=d42; expires=Thu, 31-Aug-17 18:15:00 GMT; path=/; domain=.typicode.com; HttpOnly'},
		 {'cf-ray', '2db27722e62f0479-FRA'}] 
    """   

    IO.puts response.body
	~s"""
		{
		  "userId": 1,
		  "id": 1,
		  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
		  "body": "bla bla"
		}
	"""

```

GET Request with query params
```elixir
    {:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1", [
      query_params: [
        postId: 1
      ]
    ]

    IO.inspect response.status 
    IO.inspect response.headers
    IO.puts response.body
```

POST with JSON
```elixir
    {:ok, response} = SimpleHttp.post "http://jsonplaceholder.typicode.com/posts", [
      body: "{\"name\":\"foo.example.com\"}",
      content_type: "application/json",
      timeout: 1000,
      connect_timeout: 1000
    ]

    IO.inspect response.status 
    IO.inspect response.headers
    IO.puts response.body
```

POST with params
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

    IO.inspect response.status 
    IO.inspect response.headers
    IO.puts response.body
```
