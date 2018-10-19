defmodule SimpleHttp do
  alias SimpleHttp.Request
  alias SimpleHttp.Response
  alias SimpleHttp.Exception.BadArgument

  defmacro __using__(_opts) do
    quote do
      import SimpleHttp
    end
  end

  @doc """
    Create virtual methods such as:
      SimpleHttp.get(...)
      SimpleHttp.post(...)
      SimpleHttp.delete(...)
      SimpleHttp.put(...)
      SimpleHttp.put(...)
  """
  @methods ["get", "post", "delete", "put", "options"]
  Enum.each(@methods, fn method ->
    def unquote(:"#{method}")(url, args \\ []) do
      request(String.to_atom(unquote(method)), url, args)
    end
  end)

  @spec request(atom(), String.t(), keyword()) :: {:error, any()} | {:ok, SimpleHttp.Response.t()}
  def request(method, url, args \\ []) do
    request = create_request(method, url, args)
    execute(request)
  end

  @spec execute(SimpleHttp.Request.t()) :: {:error, any()} | {:ok, SimpleHttp.Response.t()}
  defp execute(%Request{} = request) do
    httpc_response = apply(:httpc, :request, params_for_httpc(request))

    case httpc_response do
      {:ok, {{_, status, _}, headers, body}} ->
        response = %Response{
          status: status,
          headers: headers,
          body: cast_body(body)
        }

        {:ok, response}

      {:error, error} ->
        {:error, error}
    end
  end

  defp cast_body(body) when is_binary(body), do: body
  defp cast_body(body) when is_list(body), do: to_string(body)
  defp cast_body(_body), do: raise(BadArgument)

  defp params_for_httpc(%Request{} = request) do
    base_params = {request.url, request.headers}

    params =
      case request.body do
        nil ->
          base_params

        _ ->
          base_params
          |> Tuple.append(request.content_type)
          |> Tuple.append(request.body)
      end

    [
      request.method,
      params,
      request.http_options,
      request.options
    ]
  end

  defp create_request(method, url, args) do
    %Request{}
    |> add_method_to_request(method)
    |> add_url_to_request(url, args)
    |> add_headers_to_request(args)
    |> add_http_options_to_request(args)
    |> add_body_or_params_to_request(args)
    |> debug?(args)
  end

  defp add_method_to_request(%Request{} = request, method), do: %{request | method: method}

  defp add_url_to_request(%Request{} = request, url, args) do
    url =
      if String.valid?(url) do
        query_params = Keyword.get(args, :query_params)

        if is_map(query_params) || Keyword.keyword?(query_params) do
          (url <> "?" <> URI.encode_query(query_params)) |> to_charlist
        else
          url |> to_charlist
        end
      else
        raise BadArgument
      end

    %{request | url: url}
  end

  defp add_headers_to_request(%Request{} = request, args) do
    content_type_key = "Content-Type"
    content_type = args[:headers][content_type_key]

    headers =
      args[:headers][content_type_key]
      |> pop_in
      |> elem(1)
      |> Keyword.get(:headers, %{})
      |> Map.to_list()
      |> Enum.map(fn {x, y} ->
        {to_charlist(x), to_charlist(y)}
      end)

    request =
      case String.valid?(content_type) do
        true ->
          %{request | content_type: to_charlist(content_type)}

        false ->
          request
      end

    case Enum.empty?(headers) do
      true ->
        request

      false ->
        %{request | headers: headers}
    end
  end

  defp add_http_options_to_request(%Request{} = request, args) do
    keys = [:timeout, :connect_timeout, :autoredirect]

    http_options =
      Enum.reduce(keys, [], fn key, acc ->
        case args[key] do
          nil -> acc
          value -> acc ++ [{key, value}]
        end
      end)

    %{request | http_options: http_options}
  end

  defp add_body_or_params_to_request(%Request{} = request, args) do
    with body <- Keyword.get(args, :body, nil),
         params <- Keyword.get(args, :params, nil) do
      if body do
        %{request | body: body}
      else
        query =
          if params do
            params
            |> URI.encode_query()
            |> to_charlist
          else
            nil
          end

        %{request | body: query}
      end
    end
  end

  defp debug?(%Request{} = request, args) do
    case Keyword.get(args, :debug) do
      nil -> request
      _ -> IO.inspect(request)
    end
  end
end
