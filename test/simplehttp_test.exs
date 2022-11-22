defmodule SimpleHttpTest do
  use ExUnit.Case
  doctest SimpleHttp

  defmodule Test.Server do
    use Plug.Router
    require Logger

    plug(Plug.Logger)
    plug(:match)
    plug(:dispatch)

    def init(options) do
      options
    end

    def start_link do
      {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__, [])
    end

    get "/" do
      conn
      |> send_resp(200, "ok")
      |> halt
    end

    post "/" do
      conn
      |> send_resp(200, "ok")
      |> halt
    end

    put "/users/1" do
      conn
      |> send_resp(200, "ok")
      |> halt
    end

    delete "/" do
      conn
      |> send_resp(200, "ok")
      |> halt
    end
  end

  defmodule Test.Supervisor do
    use Application

    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      Application.ensure_all_started(:cowboy_telemetry)
      children = [
        %{id: __MODULE__, start: {Test.Server, :start_link, []}}
      ]

      opts = [strategy: :one_for_one, name: __MODULE__]
      Supervisor.start_link(children, opts)
    end
  end

  setup_all do
    case Test.Supervisor.start([], []) do
      {:ok, _} -> :ok
      _ -> raise "Error"
    end
  end

  test "simple get request" do
    assert {:ok, response} = SimpleHttp.get("http://localhost:4000")
    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
  end

  test "simple get request with passing a bad option" do
    assert_raise(ArgumentError, "Invalid arguments: [bad_option: 123]",
      fn -> SimpleHttp.get("http://localhost:4000", bad_option: 123) end)
  end

  test "get via request method" do
    assert {:ok, response} = SimpleHttp.request(:get, "http://localhost:4000")
    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
  end

  test "simple post request" do
    assert {:ok, response} =
             SimpleHttp.post("http://localhost:4000",
               params: [
                 title: "title is present here",
                 message: "hello world!"
               ],
               headers: %{
                 "Content-Type" => "application/x-www-form-urlencoded",
                 "Authorization" => "Bearer hash"
               },
               timeout: 1000,
               connect_timeout: 1000
             )

    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
  end

  test "post via request method" do
    assert {:ok, response} =
             SimpleHttp.request(:post, "http://localhost:4000",
               params: [
                 title: "title is present here",
                 message: "hello world!"
               ],
               headers: %{
                 "Content-Type" => "application/x-www-form-urlencoded",
                 "Authorization" => "Bearer hash"
               },
               timeout: 1000,
               connect_timeout: 1000,
               max_sessions: 5,
               verbose: :verbose
             )

    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
    assert {:ok, [{:max_sessions, 5}, {:verbose, :verbose}]} ==
           :httpc.get_options([:max_sessions, :verbose])
  end

  test "post via request method using custom profile" do
    assert {:ok, response} =
             SimpleHttp.request(:post, "http://localhost:4000",
               params: [
                 title: "title is present here",
                 message: "hello world!"
               ],
               headers: %{
                 "Content-Type" => "application/x-www-form-urlencoded",
                 "Authorization" => "Bearer hash"
               },
               timeout: 1000,
               connect_timeout: 1000,
               profile: :test,
               max_sessions: 8
             )

    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
    assert response.profile == :test
    assert {:ok, [{:max_sessions, 8}, {:verbose, false}]} ==
           :httpc.get_options([:max_sessions, :verbose], :test)
    assert :ok == SimpleHttp.close(:test)
    assert {:error, :not_found} == SimpleHttp.close(:test)
  end

  test "simple put request" do
    assert {:ok, response} =
             SimpleHttp.put("http://localhost:4000/users/1",
               params: [
                 title: "title is present here",
                 message: "hello world!"
               ],
               headers: %{
                 "Content-Type" => "application/x-www-form-urlencoded",
                 "Authorization" => "Bearer hash"
               },
               timeout: 1000,
               connect_timeout: 1000,
               verbose: false
             )

    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
    assert {:ok, [max_sessions: 5, verbose: false]} ==
           :httpc.get_options([:max_sessions, :verbose])
  end

  test "put via request method" do
    assert {:ok, response} =
             SimpleHttp.request(:put, "http://localhost:4000/users/1",
               params: [
                 title: "title is present here",
                 message: "hello world!"
               ],
               headers: %{
                 "Content-Type" => "application/x-www-form-urlencoded",
                 "Authorization" => "Bearer hash"
               },
               timeout: 1000,
               connect_timeout: 1000
             )

    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
  end

  test "simple delete request" do
    assert {:ok, response} = SimpleHttp.delete("http://localhost:4000")
    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
  end

  test "delete via request method" do
    assert {:ok, response} = SimpleHttp.request(:delete, "http://localhost:4000")
    assert response.__struct__ == SimpleHttp.Response
    assert response.body == "ok"
  end

  test "simple get with query params" do
    assert {:ok, response} =
             SimpleHttp.get("http://localhost:4000/",
               query_params: [
                 postId: 1,
                 title: "Alexandru Bagu"
               ]
             )

    assert response.__struct__ == SimpleHttp.Response
  end

  test "json post" do
    assert {:ok, response} =
             SimpleHttp.post("http://localhost:4000/",
               body: "{\"name\":\"foo.example.com\"}",
               headers: %{
                 "Content-Type" => "application/x-www-form-urlencoded",
                 "Authorization" => "Bearer hash"
               },
               timeout: 1000,
               connect_timeout: 1000
             )

    assert response.__struct__ == SimpleHttp.Response
  end
end
