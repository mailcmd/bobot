import Bobot.DSL.Base

## WARNING: You MUST not touch the 'defbot ...' line!!!
defbot :echo,
  type: :telegram,
  use_apis: [],
  use_libs: [],
  config: [
    token:
      "1A14161314121A1919181C2323282D3A24284E5055561B144831584E4E4317511B2C525B41262D4E14582F272B3B",
    session_ttl: 300_000,
    max_bot_concurrency: 1000,
    expire_message: ""
  ] do
  @connections []
  @positions [start: ""]

  hooks(start_block: :start, start_params_count: 0, stop_block: nil, fallback_block: nil)

  constants([])

  defblock :start do
    await_response store_in: message
    send_message "You say: #{message}"
    call_block :start
  end
end