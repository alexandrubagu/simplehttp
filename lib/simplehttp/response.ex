defmodule SimpleHttp.Response do
  @moduledoc """
  Defines a http response
  """
  @type t :: %__MODULE__{}

  defstruct status: nil,
            headers: [],
            body: nil
end
