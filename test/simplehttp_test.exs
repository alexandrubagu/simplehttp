defmodule SimpleHttpTest do
  use ExUnit.Case
  doctest SimpleHttp

  setup_all do
    SimpleHttp.start
  end

  test "simple get request" do
    assert {:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1"
    assert response.__struct__ == SimpleHttp.Response
  end

  test "simple get with query params" do
    assert {:ok, response} = SimpleHttp.get "http://jsonplaceholder.typicode.com/posts/1", [
      query_params: [
        postId: 1
      ]
    ]
    assert response.__struct__ == SimpleHttp.Response
  end

  test "json post" do
    assert {:ok, response} = SimpleHttp.post "http://jsonplaceholder.typicode.com/posts", [
      body: "{\"name\":\"foo.example.com\"}",
      content_type: "application/json",
      timeout: 1000,
      connect_timeout: 1000
    ]
    assert response.__struct__ == SimpleHttp.Response
  end

  test "post with params" do
    assert {:ok, response} = SimpleHttp.post "http://jsonplaceholder.typicode.com/posts", [
      params: [
        title: "title is present here",
        message: "hello world!"
      ],
      content_type: "application/x-www-form-urlencoded",
      timeout: 1000,
      connect_timeout: 1000
    ]
    assert response.__struct__ == SimpleHttp.Response
  end
end
