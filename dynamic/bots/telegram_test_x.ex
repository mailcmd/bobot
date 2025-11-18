import Bobot.DSL.Base

defbot :telegram_test_x,
  type: :telegram,
  use_apis: [:test],
  use_libs: [],
  config: [
    token: "8241208776:AAHz1-OjK94w_L0RIuIDoReuaZnJX0IWSXI",
    session_ttl: 3600,
    max_bot_concurrency: 1000,
    expire_message: "El tiempo de espera se agotó. Empezá de nuevo."
  ] do
  hooks(
    start_block: :start,
    start_params_count: 0,
    stop_block: :first_contact,
    fallback_block: :good_bye
  )

  defblock :start, receive: phone do
    session_store(time: System.os_time(:second))
    send_message "<b>Bienvenido #{value_of(:first_name)}!</b>"
    call_block :first_contact, params: phone
  end

  defblock :good_bye do
    call_api :save_interaction
    terminate message: "Gracias por comunicarte con nosotros!"
  end

  defblock :first_contact, receive: phone do
    call_api :is_first_contact, params: phone

    if value_of(:first_contact, is: true) do
      send_message "Ingresá tu ID de cliente o DNI"
      await_response store_in: id_dni
      call_api :addresses_menu, params: id_dni
      send_message "Escribiste #{id_dni}, dejame ver si encuentro tu dirección..."
      call_block :addresses_menu
    else
      call_block :addresses_menu
    end
  end

  defblock :addresses_menu do
    send_menu message: "Cuál es tu domicilio?", menu: value_of(:menu)
    await_response store_in: user_input, cast_as: :integer
    edit_message message: "Elegiste: #{value_of(:menu |> Enum.at(user_input - 1))}!", menu: []

    if user_input == value_of(:correct_item) do
      call_block :first_check
    else
      send_message "No pudimos identificarte, probemos otra cosa..."
      call_block :first_contact, params: -1
    end
  end

  defblock :first_check do
    call_api :client_status, params: value_of(:id)

    if value_of(:status, is: :suspend) do
      send_message "Estás suspendido macho, pagá y después charlamos."
    else
      send_message "Capo!!! Sos un buen cliente!!"
    end
  end
end