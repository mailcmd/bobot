import Bobot.DSL.Base

## WARNING: You MUST not touch the 'deflib ...' line!!!
deflib :common do
  def is_command?([47 | _]) do
    true
  end

  def is_command?([_ | _]) do
    false
  end

  def is_command?(text) do
    is_command?(String.to_charlist(text))
  end

  def build_channel("/group", group_channel, _uid) do
    group_channel
  end

  def build_channel(text, _group_channel, uid) do
    text |> String.replace("/", "") |> String.replace("_", "#") |> Kernel.<>(",#{uid}")
  end

  def get_operator_name("/group", _providers) do
    "grupo de soporte"
  end

  def get_operator_name(text, providers) do
    uid = String.replace(text, "/chat_", "")
    Enum.find(providers, fn pvd -> pvd[:uid] == uid end)[:name]
  end
end