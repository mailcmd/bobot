import Bobot.DSL.Base

## WARNING: You MUST not touch the 'defbot ...' line!!!
defbot :test_session,
  type: :telegram,
  use_apis: [],
  use_libs: [],
  config: [
    token: "8241208776:AAHz1-OjK94w_L0RIuIDoReuaZnJX0IWSXI",
    session_ttl: 300_000,
    max_bot_concurrency: 1000,
    expire_message: "chau"
  ] do
  hooks(start_block: :start, start_params_count: 0, stop_block: :stop, fallback_block: nil)

  defcommand "/stop" do
    terminate(message: "Ok, good bye!")
  end

  defcommand "/test" do
    send_message "Interrumpo y ahora debería volver"
  end

  defblock :start do
    session_store(secret_number: Enum.random(1..10))
    session_store(attempts: 0)
    send_message "Guess the number between 1 and 10 that I'm thinking of..."
    call_block :loop
  end

  defblock :loop do
    await_response store_in: number_try, cast_as: :integer

    case session_value(:secret_number) do
      ^number_try ->
        send_message "You win in #{session_value(:attempts) + 1} attempts!!"
        break()

      secret_number when secret_number < number_try ->
        send_message "It is lower, try again..."
        session_store(attempts: session_value(:attempts) + 1)

      secret_number when secret_number > number_try ->
        send_message "It is higher, try again..."
        session_store(attempts: session_value(:attempts) + 1)
    end

    call_block :loop
  end

  defblock :stop do
    send_message "Hasta la vista, baby!"
  end
end