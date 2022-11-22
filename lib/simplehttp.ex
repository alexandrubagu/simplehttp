defmodule SimpleHttp do
  @moduledoc """
  Implements a simple HTTP client that uses inets application included in the OTP.
  """
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
    request = %Request{args: args} = create_request(method, url, args)
    {profile, args} = init_httpc(args)
    args != [] && raise ArgumentError, message: "Invalid arguments: #{inspect(args)}"
    execute(%{request | args: args, profile: profile})
  end

  @doc "Stop the HTTP client profile"
  @spec close(atom() | Response.t() | nil) :: :ok | {:error, any()}
  def close(nil), do: :ok

  def close(:inets),
    do: raise(ArgumentError, message: "To stop default profile use :inets.stop()")

  def close(profile) when is_atom(profile), do: :inets.stop(:httpc, profile)
  def close(%Response{profile: profile}), do: close(profile)

  @spec execute(SimpleHttp.Request.t()) :: {:error, any()} | {:ok, SimpleHttp.Response.t()}
  defp execute(%Request{} = req) do
    params =
      (req.body && {req.url, req.headers, req.content_type, req.body}) || {req.url, req.headers}

    httpc_response =
      case req.profile do
        :inets ->
          :httpc.request(req.method, params, req.http_options, req.options)

        profile ->
          :httpc.request(req.method, params, req.http_options, req.options, profile)
      end

    case httpc_response do
      {:ok, {{_, status, _}, headers, body}} ->
        response = %Response{
          status: status,
          headers: headers,
          body: cast_body(body),
          profile: req.profile
        }

        {:ok, response}

      {:ok, :saved_to_file} ->
        {:ok, %Response{status: 200, body: :saved_to_file, profile: req.profile}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp cast_body(body) when is_binary(body), do: body
  defp cast_body(body) when is_list(body), do: to_string(body)
  defp cast_body(_body), do: raise(BadArgument)

  defp create_request(method, url, args) do
    %Request{args: args}
    |> add_method_to_request(method)
    |> add_url_to_request(url)
    |> add_headers_to_request()
    |> add_http_options_to_request()
    |> add_options_to_request()
    |> add_body_or_params_to_request()
    |> debug?()
  end

  defp add_method_to_request(%Request{} = request, method), do: %{request | method: method}

  defp add_url_to_request(%Request{args: args} = request, url) do
    String.valid?(url) || raise BadArgument, message: "URL must be a string"
    {query_params, args} = Keyword.pop(args, :query_params)

    url =
      if is_map(query_params) || Keyword.keyword?(query_params) do
        url <> "?" <> URI.encode_query(query_params)
      else
        url
      end

    %Request{request | url: cstr(url), args: args}
  end

  defp add_headers_to_request(%Request{args: args} = request) do
    content_type_key = "Content-Type"
    {headers, args} = Keyword.pop(args, :headers, %{})
    {content_type, headers} = pop_in(headers[content_type_key])

    headers =
      if headers do
        Enum.map(headers, fn {x, y} -> {to_charlist(x), y} end)
      else
        %{}
      end

    request =
      if String.valid?(content_type) do
        %{request | content_type: to_charlist(content_type)}
      else
        request
      end

    request =
      if Enum.empty?(headers) do
        request
      else
        %Request{request | headers: headers}
      end

    %Request{request | args: args}
  end

  @http_options MapSet.new([
                  :timeout,
                  :connect_timeout,
                  :autoredirect,
                  :ssl,
                  :essl,
                  :proxy_auth,
                  :version,
                  :relaxed
                ])
  defp add_http_options_to_request(%Request{args: args} = request) do
    {http_options, args} = filter_options(@http_options, args)

    %Request{request | http_options: http_options, args: args}
  end

  @req_options MapSet.new([
                 :sync,
                 :stream,
                 :body_format,
                 :full_result,
                 :headers_as_is,
                 :socket_opts,
                 :receiver,
                 :ipv6_host_with_brackets
               ])
  defp add_options_to_request(%Request{args: args} = request) do
    {options, args} = filter_options(@req_options, args)

    %Request{request | options: options, args: args}
  end

  @global_options MapSet.new([
                    :proxy,
                    :https_proxy,
                    :max_sessions,
                    :max_keep_alive_length,
                    :keep_alive_timeout,
                    :max_pipeline_length,
                    :pipeline_timeout,
                    :cookies,
                    :ipfamily,
                    :ip,
                    :port,
                    :socket_opts,
                    :verbose,
                    :unix_socket
                  ])
  defp init_httpc(args) do
    {options, args} = filter_options(@global_options, args)
    {profile, args} = Keyword.pop(args, :profile)

    res = (profile && :inets.start(:httpc, profile: profile)) || :inets.start()

    pid =
      case res do
        {:ok, pid} ->
          pid

        {:error, {:already_started, pid}} ->
          pid

        {:error, error} ->
          raise RuntimeError, message: "Cannot start httpc: #{inspect(error)}"
      end

    options != [] && set_httpc_options(profile, pid, options)

    {profile || :inets, args}
  end

  defp set_httpc_options(profile, pid, options) do
    case (profile && :httpc.set_options(options, pid)) || :httpc.set_options(options) do
      :ok ->
        :ok

      {:error, err} ->
        raise BadArgument,
          message: "Error setting httpc options #{inspect(options)}: #{inspect(err)}"
    end
  end

  defp add_body_or_params_to_request(%Request{args: args} = request) do
    case Keyword.pop(args, :body) do
      {nil, _} ->
        case Keyword.pop(args, :params) do
          {nil, _} ->
            request

          {params, args} ->
            query =
              params
              |> URI.encode_query()
              |> to_charlist

            %Request{request | body: query, args: args}
        end

      {body, args} ->
        %Request{request | body: body, args: args}
    end
  end

  defp filter_options(keys, args) do
    {opts, args} = Enum.split_with(args, fn {k, _} -> MapSet.member?(keys, k) end)

    options =
      opts
      |> Enum.map(fn {k, v} -> {k, option_value(k, v)} end)
      |> Enum.filter(fn {_, v} -> v != nil end)

    {options, args}
  end

  defp option_value(_, nil), do: nil
  defp option_value(:stream, v), do: cstr(v)
  defp option_value(:proxy_auth, {u, p}), do: {cstr(u), cstr(p)}
  defp option_value(:body_format, v), do: cstr(v)
  defp option_value(:proxy, {{h, p}, np}), do: {{cstr(h), p}, list_cstr(np)}
  defp option_value(:https_proxy, {{h, p}, np}), do: {{cstr(h), p}, list_cstr(np)}
  defp option_value(:unix_socket, v), do: cstr(v)
  defp option_value(_, v), do: v

  defp cstr(v) when is_binary(v), do: String.to_charlist(v)
  defp cstr(v), do: v

  defp list_cstr(v) when is_list(v), do: for(i <- v, do: cstr(i))
  defp list_cstr(v), do: cstr(v)

  defp debug?(%Request{args: args} = request) do
    case Keyword.get(args, :debug) do
      nil -> request
      _ -> IO.puts("Request: #{inspect(request, pretty: true)}")
    end
  end
end
