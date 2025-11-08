defmodule Bobot.Bot.TelegramTest do
  use Bobot.Bot,
    type: :telegram,
    config: [
      token: "8241208776:AAHz1-OjK94w_L0RIuIDoReuaZnJX0IWSXI",
      session_ttl: 10 * 1_000,
      max_bot_concurrency: 1_000,
      expire_message: "El tiempo de espera se agotó. Empezá de nuevo.",
      use_api: Bobot.API.Test
    ]

  hooks [
    start_block: :start,
    start_params: phone,
    stop_block: :good_bye,
    fallback_block: :good_bye
  ]

  ## COMMANDS

  command "/start" do
    call_block :start, params: value_of(:chat_id)
    call_block :good_bye
  end

  command "/stop" do
    call_block :good_bye
  end

  command "/test1" do
    send message: "Enviaste el commando TEST1 con #{inspect session_data()}!"
    call_block :good_bye
  end

  command "/test2" do
    call_block :start, params: -1
    call_block :good_bye
  end

  ## BLOCKS
  block :start, receive: phone do
    session_store time: System.os_time(:second)
    send message: "<b>Bienvenido #{value_of(:first_name)}!</b>"
    call_block :first_contact, params: phone
  end

  block :good_bye do
    call_api :save_interaction
    terminate message: "Gracias por comunicarte con nosotros!"
  end

  block :first_contact, receive: phone do
    call_api :is_first_contact, params: phone
    if value_of :first_contact, is: true do
      send message: "Ingresá tu ID de cliente o DNI"
      await_response store_in: id_dni
      call_api :addresses_menu, params: id_dni
      send message: "Escribiste #{id_dni}, dejame ver si encuentro tu dirección..."
      call_block :addresses_menu
    else
      call_block :addresses_menu
    end
  end

  block :addresses_menu do
    send message: "Cuál es tu domicilio?", menu: value_of(:menu)
    await_response store_in: user_input, cast_as: :integer
    edit_message message: "Elegiste: #{value_of(:menu) |> Enum.at(user_input-1)}!", menu: []

    if user_input == value_of(:correct_item) do
      call_block :first_check
    else
      send message: "No pudimos identificarte, probemos otra cosa..."
      call_block :first_contact, params: -1
    end
  end

  block :first_check do
    call_api :client_status, params: value_of :id
    if value_of :status, is: :suspend do
      send message: "Estás suspendido macho, pagá y después charlamos."
    else
      send message: "Capo!!! Sos un buen cliente!!"
    end
  end

end
