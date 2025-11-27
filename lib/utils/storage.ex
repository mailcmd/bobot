defmodule Bobot.Utils.Storage do
  @moduledoc """
  - Store datas of running bots.
  - The key of any data es {token, <data_key>}
    * { token, :module }
    * { token, :session_ttl }
    * { token, :expire_message }
    * { token, :commands_as_message }
    * { token, {:chat, <chat_id>, :sess_id} } # string
    * { token, {:chat, <chat_id>, :processes} # {pid_bot, pid_engine}

  """
  use Agent

  def start_link(name: name) do
    Agent.start_link(fn -> %{} end, name: name)
  end
  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set_token_data(token, key, value) do
    Agent.update(__MODULE__, fn status -> put_in(status, [{token, key}], value) end)
  end
  def get_token_data(token, key) do
    Agent.get(__MODULE__, fn status -> Map.get(status, {token, key}) end)
  end
  def remove_token_data(token, key) do
    Agent.get(__MODULE__, fn status -> Map.delete(status, {token, key}) end)
  end
end
