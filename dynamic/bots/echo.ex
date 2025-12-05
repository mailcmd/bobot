import Bobot.DSL.Base

## WARNING: You MUST not touch the 'defbot ...' line!!!
defbot :echo,
  type: :telegram,
  use_apis: [],
  use_libs: [],
  config: [
    token: "8241208776:AAHz1-OjK94w_L0RIuIDoReuaZnJX0IWSXI",
    session_ttl: 300_000,
    max_bot_concurrency: 1000,
    expire_message: ""
  ] do
  @positions [start: ""]
  @connections []

  hooks(start_block: :start, start_params_count: 0, stop_block: nil, fallback_block: nil)

  constants([])

  defblock :start do
    await_response store_in: message
    send_message "You say: #{message}"
    call_block :start
  end
end