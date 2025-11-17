defmodule Bobot.Application do
  @moduledoc false

  use Application
  @bots_dir Application.compile_env(:bobot, :bots_dir)
  @apis_dir Application.compile_env(:bobot, :apis_dir)

  @impl Application
  def start(_type, _args) do
    # webhook_config = [
    #   host: Keyword.fetch!(config, :host),
    #   local_port: Keyword.fetch!(config, :local_port)
    # ]

    Enum.map(Application.get_env(:bobot, :telegram_bots, []), fn name ->
      Code.compile_file("#{@bots_dir}/#{name}.ex")
    end)

    Path.wildcard("#{@apis_dir}/*.ex") |> Enum.map(fn filename ->
      Code.compile_file(filename)
    end)

    children = [
      {DNSCluster, query: Application.get_env(:bobot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bobot.PubSub},
      BobotWeb.Endpoint,
      {Bobot.Bot.Assigns, []},
      {Bobot.Engine.Telegram.Storage, []},
      {Finch, name: Bobot.Finch}
      # {Telegram.Webhook, config: webhook_config, bots: [{Bobot.Engine.Telegram, bot_config}]}
      # {Telegram.Poller, bots: [{Bobot.Engine.Telegram, bot_config}]},
    ]
    ++
    Enum.map(Application.get_env(:bobot, :telegram_bots, []), fn name ->
      bot_module = ("Elixir.Bobot.Bot.#{Macro.camelize("#{name}")}"
        |> String.to_existing_atom)
      bot_config = :attributes |> bot_module.__info__() |> Keyword.fetch!(:bot_config)
      token = Keyword.fetch!(bot_config, :token)
      session_ttl = Keyword.fetch!(bot_config, :session_ttl)
      expire_message = Keyword.get(bot_config, :expire_message, "👏")
      commands_as_message = Keyword.get(bot_config, :commands_as_message, false)
      :timer.apply_after(3_000, fn ->
        Bobot.Engine.Telegram.Storage.set_token_data(token, :module, bot_module)
        Bobot.Engine.Telegram.Storage.set_token_data(token, :session_ttl, session_ttl)
        Bobot.Engine.Telegram.Storage.set_token_data(token, :expire_message, expire_message)
        Bobot.Engine.Telegram.Storage.set_token_data(token, :commands_as_message, commands_as_message)
      end)
      {Telegram.Poller, bots: [{Bobot.Engine.Telegram, bot_config}]}
    end)

    opts = [strategy: :one_for_one, name: Bobot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BobotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

end
