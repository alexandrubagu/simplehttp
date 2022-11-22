defmodule SimpleHttp.Request do
  @moduledoc """
  Defines a http request
  """
  @type t :: %__MODULE__{}

  defstruct method: nil,
            url: nil,
            headers: [],
            content_type: nil,
            body: nil,
            http_options: [],
            options: [],
            profile: nil,
            headers_format: nil,
            args: []
end
