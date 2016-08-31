
defmodule SimpleHttp.Request do
  defstruct method: nil,
            url: nil,
            headers: [],
            content_type: nil,
            body: nil,
            http_options: [],
            options: []
end