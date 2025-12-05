defmodule Bobot.DSL.Telegram.Templates do
  # import Phoenix.Component

  def show("settings", assigns) do
    Phoenix.Template.render(BobotWeb.DSLTemplates, "settings", "html", assigns)
  end

  def save("settings", params, _assigns) do
    {:ok, "Settings saved succesfully!", [
      token: params["token"],
      session_ttl:
        String.to_integer( params["session_ttl"] != "" && params["session_ttl"] || "300000" ),
      max_bot_concurrency: 1000,
      expire_message: params["expire_message"]
    ]}
  end

end
