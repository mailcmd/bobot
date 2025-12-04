defmodule BobotWeb.RestApi do
  use BobotWeb, :controller
  use Gettext, backend: BobotWeb.Gettext

  alias Plug.Conn

  def index(conn, params) do
    bot_channel = params["bot_channel"] |> String.split(":") |> Enum.map(&String.to_atom/1)
    with [bot_name, channel] <- bot_channel,
         module <- Bobot.Utils.get_bot_module(bot_name),
         message when is_map(message) <- extract_message(conn, params) do

      {bot_name, channel}
        |> Bobot.Utils.get_channel_subscribers()
        |> module.inform_to_subscribers(message)

      Conn.send_resp(conn, 200, "{ \"delivered_ok\": true }")
    else
      nil -> request_error(conn, nil, "Bot does not exists!")
      msg when is_binary(msg) -> request_error(conn, nil, msg)
      _ -> request_error(conn, nil)
    end
  end

  def request_error(conn, _params, error_message \\ "Malformed request!") do
    Conn.send_resp(conn, 400, "{ \"delivered_ok\": false,  \"error\": \"#{error_message}\" }")
  end

  defp extract_message(conn, params) do
    case {conn.method, params["text"], conn.body_params} do
      {"GET", [text], _} ->
        %{type: :text, text: text}

      {"GET", [], _} ->
        "Missing message text!"

      {"POST", _, %{type: "text", text: text}} ->
        %{type: :text, text: text}

      {"POST", _, %{type: "image", filename: filename}} ->
        %{type: :image, filename: filename}

      {"POST", _, %{type: "image", url: url}} ->
        %{type: :image, url: url}

      _ ->
       "Malformed request!"
    end
  end

end
