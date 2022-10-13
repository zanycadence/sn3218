defmodule Sn3218.Channel do
  @moduledoc false

  alias __MODULE__

  defstruct [:id, :enabled?, :output]

  @type t() :: %__MODULE__{id: integer, enabled?: boolean, output: integer}

  def init_channel(channel_id) do
    %Channel{id: channel_id, enabled?: false, output: 0}
  end
end
