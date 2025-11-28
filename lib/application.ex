defmodule Bobot.Application do
  @moduledoc false

  use Application
  require Logger

  @bots_dir Application.compile_env(:bobot, :bots_dir)
  @apis_dir Application.compile_env(:bobot, :apis_dir)
  @libs_dir Application.compile_env(:bobot, :libs_dir)

  @impl Application
  def start(_type, _args) do
    # webhook_config = [
    #   host: Keyword.fetch!(config, :host),
    #   local_port: Keyword.fetch!(config, :local_port)
    # ]

    # init static_db
    :dets.open_file(:static_db, file: ~c"priv/static.db")

    # init volatile_db
    :ets.new(:volatile_db, [
      :public,
      :named_table,
      write_concurrency: true,
      read_concurrency: true
    ])

    # Compile APIs
    Path.wildcard("#{@apis_dir}/*.ex") |> Enum.map(fn filename ->
      try do
        Bobot.Utils.compile_file(filename)
      rescue
        error -> Logger.log(:error, "[BOBOT] There was a problem compiling #{filename} (#{inspect error})")
      end
    end)

    # Compile Libs
    Path.wildcard("#{@libs_dir}/*.ex") |> Enum.map(fn filename ->
      try do
        Bobot.Utils.compile_file(filename)
      rescue
        error -> Logger.log(:error, "[BOBOT] There was a problem compiling #{filename} (#{inspect error})")
      end
    end)


    # Compile bots
    bobot_config = Bobot.Config.__info__(:attributes)
    telegram_bots = Keyword.get(bobot_config, :telegram_bots, [])

    telegram_bots=
      Enum.map(telegram_bots, fn name ->
        Logger.log(:notice, "[BOBOT] Compiling #{name} bot...")
        case Bobot.Utils.compile_file("#{@bots_dir}/#{name}.ex") do
          {{:error, message}, _} ->
            Logger.log(:error, "[BOBOT] There was a problem compiling #{@bots_dir}/#{name}.ex (#{message})")
            nil
          _ ->
            name
        end
      end)
      |> Enum.filter(&(&1 != nil))

    # Set supervisor childrens
    children = [
      {DNSCluster, query: Application.get_env(:bobot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bobot.PubSub},
      BobotWeb.Endpoint,
      {Bobot.Utils.Assigns, []},
      {Bobot.Utils.Storage, []},
      {Finch, name: Bobot.Finch},
      # {Telegram.Webhook, config: webhook_config, bots: [{Bobot.Engine.Telegram, bot_config}]}
      # {Telegram.Poller, bots: [{Bobot.Engine.Telegram, bot_config}]},
      {
        Telegram.Poller, bots: Enum.map(telegram_bots, fn name ->
          ## For every telegram bot...
          Logger.log(:notice, "[BOBOT] Initializing #{name} bot...")
          init_telegram_bot(name)
        end)
      }
    ]
    ++
    [Bobot.Task]

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

  ################################################################################################
  ################################################################################################
  ################################################################################################

  def init_telegram_bot(name) do
    bot_module = Bobot.Utils.get_bot_module(name)

    ## check if bot has channels and init
    bot_channels = :attributes |> bot_module.__info__() |> Keyword.get(:bot_channels, [])
    Logger.log(:notice, "[BOBOT] Bot #{name} has channels: #{inspect bot_channels}")
    Logger.log(:notice, "[BOBOT] Init all channels...")
    bot_module.init_channels()
    # Enum.each(bot_channels, fn channel ->
    #   Logger.log(:notice, "[BOBOT] Bot #{name} init channel #{channel}")
    #   bot_module.init_channel(channel)
    # end)

    ## get bot config
    bot_config = :attributes |> bot_module.__info__() |> Keyword.fetch!(:bot_config)
    token = Keyword.fetch!(bot_config, :token)
    session_ttl = Keyword.fetch!(bot_config, :session_ttl)
    expire_message = Keyword.get(bot_config, :expire_message, "👏")
    commands_as_message = Keyword.get(bot_config, :commands_as_message, false)
    :timer.apply_after(3_000, fn ->
      Bobot.Utils.Storage.set_token_data(token, :module, bot_module)
      Bobot.Utils.Storage.set_token_data(token, :session_ttl, session_ttl)
      Bobot.Utils.Storage.set_token_data(token, :expire_message, expire_message)
      Bobot.Utils.Storage.set_token_data(token, :commands_as_message, commands_as_message)
    end)
    {Bobot.Engine.Telegram, bot_config}
    # {Bobot.Engine.Telegram, [{:name, name} | bot_config]}
  end


end
