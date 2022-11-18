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
      SimpleHttp.options(...)
      SimpleHttp.head(...)
      SimpleHttp.patch(...)
      SimpleHttp.trace(...)
  """
  @methods ["get", "post", "delete", "put", "options", "head", "patch", "trace"]
  Enum.each(@methods, fn method ->
    def unquote(:"#{method}")(url, args \\ []) do
      request(String.to_atom(unquote(method)), url, args)
    end
  end)

  @spec request(atom(), String.t(), keyword()) :: {:error, any()} | {:ok, SimpleHttp.Response.t()}
  def request(method, url, args \\ []) do
    request = create_request(method, url, args)
    if request.global_options != [] do
      case :httpc.set_options(request.global_options) do
        :ok ->
          :ok
        {:error, err} ->
          raise BadArgument, message: "Error setting global options: #{err}"
      end
    end
    execute(request)
  end

  @spec execute(SimpleHttp.Request.t()) :: {:error, any()} | {:ok, SimpleHttp.Response.t()}
  defp execute(%Request{} = req) do
    params = req.body && {req.url, req.headers, req.content_type, req.body} || {req.url, req.headers}

    httpc_response = :httpc.request(req.method, params, req.http_options, req.options)

    case httpc_response do
      {:ok, {{_, status, _}, headers, body}} ->
        response = %Response{
          status: status,
          headers: headers,
          body: cast_body(body)
        }

        {:ok, response}

      {:ok, :saved_to_file} = response ->
        response

      {:error, error} ->
        {:error, error}
    end
  end

  defp cast_body(body) when is_binary(body), do: body
  defp cast_body(body) when is_list(body), do: to_string(body)
  defp cast_body(_body), do: raise(BadArgument)

  defp create_request(method, url, args) do
    %Request{}
    |> add_method_to_request(method)
    |> add_url_to_request(url, args)
    |> add_headers_to_request(args)
    |> add_global_options(args)
    |> add_http_options_to_request(args)
    |> add_options_to_request(args)
    |> add_body_or_params_to_request(args)
    |> debug?(args)
  end

  defp add_method_to_request(%Request{} = request, method), do: %{request | method: method}

  defp add_url_to_request(%Request{} = request, url, args) do
    String.valid?(url) || raise BadArgument, message: "URL must be a string"
    query_params = Keyword.get(args, :query_params)

    url =
      if is_map(query_params) || Keyword.keyword?(query_params) do
        (url <> "?" <> URI.encode_query(query_params))
      else
        url
      end

    %{request | url: cstr(url)}
  end

  defp add_headers_to_request(%Request{} = request, args) do
    content_type_key = "Content-Type"
    {content_type, headers} = pop_in(args[:headers][content_type_key])

    headers =
      headers
      |> Keyword.get(:headers, %{})
      |> Enum.map(fn {x,y} -> {to_charlist(x), to_charlist(y)} end)

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
    keys = [
      :timeout, :connect_timeout, :autoredirect,
      :ssl, :essl, :proxy_auth, :version, :relaxed
    ]
    http_options = filter_options(keys, args)

    %{request | http_options: http_options}
  end

  defp add_options_to_request(%Request{} = request, args) do
    keys = [
      :sync, :stream, :body_format, :full_result, :headers_as_is,
      :socket_opts, :receiver, :ipv6_host_with_brackets
    ]
    options = filter_options(keys, args)

    %{request | options: options}
  end

  defp add_global_options(%Request{} = request, args) do
    keys = [
      :proxy,                 :https_proxy,           :max_sessions,
      :max_keep_alive_length, :keep_alive_timeout,    :max_pipeline_length,
      :pipeline_timeout,      :cookies,               :ipfamily,
      :ip,                    :port,                  :socket_opts,
      :verbose,               :unix_socket
    ]
    options = filter_options(keys, args)

    %{request | global_options: options}
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

  defp filter_options(keys, args) do
    Enum.map(keys, &{&1, option_value(&1, args[&1])})
    |> Enum.filter(fn {_,v} -> v != nil end)
  end

  defp option_value(_, nil),                   do: nil
  defp option_value(:stream, v),               do: cstr(v)
  defp option_value(:proxy_auth, {u,p}),       do: {cstr(u), cstr(p)}
  defp option_value(:body_format, v),          do: cstr(v)
  defp option_value(:proxy, {{h,p},np}),       do: {{cstr(h),p},list_cstr(np)}
  defp option_value(:https_proxy, {{h,p},np}), do: {{cstr(h),p},list_cstr(np)}
  defp option_value(:unix_socket, v),          do: cstr(v)
  defp option_value(_, v),                     do: v

  defp cstr(v) when is_binary(v),              do: String.to_charlist(v)
  defp cstr(v),                                do: v

  defp list_cstr(v) when is_list(v),           do: for i <- v, do: cstr(i)
  defp list_cstr(v),                           do: cstr(v)

  defp debug?(%Request{} = request, args) do
    case Keyword.get(args, :debug) do
      nil -> request
      _ -> IO.inspect(request)
    end
  end
end
