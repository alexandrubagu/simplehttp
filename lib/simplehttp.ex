defmodule SimpleHttp do
  @docmodule """
     #Author: Alexandru Bagu
     #Email: contact@alexandrubagu.info

     Create virtual methods:
      SimpleHttp.get(...)
      SimpleHttp.post(...)
      SimpleHttp.delete(...)
      SimpleHttp.put(...)
      SimpleHttp.put(...)
  """
  alias SimpleHttp.Request
  alias SimpleHttp.Response
  alias SimpleHttp.Exception.BadArgument

  defmacro __using__(_opts) do
    quote do
      import SimpleHttp
    end
  end

  # http://erlang.org/doc/man/httpc.html
  methods = ["get", "post", "delete", "put", "options"]

  Enum.each(methods, fn method ->
    def unquote(:"#{method}")(url, args \\ []) do
      create_request(unquote(String.to_atom(method)), url, args)
      |> execute
    end
  end)

  @doc """
    Before you use this module you SHOULD call SimpleHttp.start
  """
  def start do
    case :inets.start() do
      :ok -> :ok
      {:error, {:already_started, _}} -> :ok
      _ -> :error
    end
  end

  defp execute(request) do
    response = struct(Response)

    httpc_response =
      if request.body do
        :httpc.request(
          request.method,
          {
            request.url,
            request.headers,
            request.content_type,
            request.body
          },
          request.http_options,
          request.options
        )
      else
        :httpc.request(
          request.method,
          {
            request.url,
            request.headers
          },
          request.http_options,
          request.options
        )
      end

    case httpc_response do
      {:ok, {status, headers, body} } ->
        {:ok, %{ response | 
            status: status,
            headers: headers, 
            body: cond do
              String.valid?(body) -> body
              is_list(body) -> to_string(body)
              true -> raise BadArgument
            end
          } 
        }
      {:error, error } -> IO.inspect error
    end
  end

  defp create_request(method, url, args) do
    # create struct
    request = struct(Request)

    # update method (post/get/put/patch/detele)
    request = %{request | method: method}

    url =
      if String.valid?(url) do
        if is_map(args[:query_params]) || Keyword.keyword?(args[:query_params]) do
          (url <> "?" <> URI.encode_query(args[:query_params])) |> to_charlist
        else
          url |> to_charlist
        end
      else
        raise BadArgument
      end

    request = %{request | url: url}

    request =
      with body <- args[:body],
           params <- args[:params] do
        if body do
          %{request | body: body}
        else
          query =
            if params do
              URI.encode_query(params) |> to_charlist
            else
              nil
            end

          %{request | body: query}
        end
      end

    request =
      if String.valid?(args[:content_type]) do
        %{request | content_type: to_charlist(args[:content_type])}
      else
        %{request | content_type: args[:content_type]}
      end

    keys = [:timeout, :connect_timeout, :autoredirect]

    http_options =
      Enum.filter_map(
        keys,
        fn key ->
          args[key]
        end,
        fn key ->
          Tuple.append(Tuple.append({}, key), args[key])
        end
      )

    request = %{request | http_options: http_options}

    if args[:debug] do
      IO.puts("------------ DEBUG --------------")
      IO.inspect(request)
      IO.puts("------------ DEBUG --------------")
    end

    request
  end
end
