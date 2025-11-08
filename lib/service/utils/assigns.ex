defmodule Bobot.Bot.Assigns do
  import Kernel, except: [get_in: 2, put_in: 3]
  use Agent
  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end
  def get_all(sess_id) do
    Agent.get(__MODULE__, fn assigns -> assigns[sess_id] end)
  end
  def set_all(sess_id, assigns) do
    Agent.update(__MODULE__, fn _ -> Map.put(assigns, sess_id, assigns) end)
  end
  def get(sess_id, key) do
    Agent.get(__MODULE__, fn assigns -> Kernel.get_in(assigns, [sess_id, key]) end)
  end
  def get_in(sess_id, keys) when is_list(keys) do
    Agent.get(__MODULE__, fn assigns -> Kernel.get_in(assigns, [sess_id | keys]) end)
  end
  def put_in(sess_id, keys, value) when is_list(keys) do
    Agent.update(__MODULE__, fn assigns -> Kernel.put_in(assigns, [sess_id | keys], value) end)
  end
  def put(sess_id, key, value) do
    Agent.update(__MODULE__, fn assigns -> Kernel.put_in(assigns, [sess_id, key], value) end)
  end
  def unset(sess_id) do
    Agent.update(__MODULE__, fn assigns -> Map.delete(assigns, sess_id) end)
  end
end
