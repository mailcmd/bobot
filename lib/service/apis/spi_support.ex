defmodule Bobot.API.SPISupport do
  use Bobot.API
  require Logger

  @url "https://spiprovisioning.com/spi-support-tool/backend/proxy.php"

  @impl true
  def call(:authenticate, muid) do
    with  {:ok, %Tesla.Env{body: body}} <- Tesla.get("#{@url}?action=login&muid=#{muid}"),
          %{result: user_data} <- Jason.decode!(body, keys: :atoms) do
      group_channel = user_data[:channels]
        |> Enum.filter(fn ch ->
          (ch |> String.split(",") |> length()) > 2
        end)
        |> hd()
      %{user_data:  user_data, group_channel: group_channel, current_channel: group_channel}
    else
      _ -> %{user_data: :error}
    end
  end

  def call(:send_message, [user, channel, message]) do
    mid = System.os_time(:millisecond)
    "#{@url}?action=send&from_telegram=yes&mid=#{mid}&user=#{user}&channel=#{channel}&message=#{message}"
      |> URI.encode()
      |> URI.encode(&(&1 != ?#))
      |> Tesla.get()
      # |> IO.inspect
      |> case do
        {:error, _} -> %{last_message: :error}
        {:ok, _} -> %{last_message: :ok}
      end
  end

  def call(:send_image, [user, channel, image]) do
    mid = System.os_time(:millisecond)
    Tesla.client([
        {Tesla.Middleware.FormUrlencoded,
          encode: &Plug.Conn.Query.encode/1,
          decode: &Plug.Conn.Query.decode/1}
      ])
      |> Tesla.post(@url, %{
        action: "send",
        from_telegram: "yes",
        mid: mid,
        user: user,
        channel: channel,
        image: image
      })
      # |> IO.inspect
      |> case do
        {:error, _} -> %{last_message: :error}
        {:ok, _} -> %{last_message: :ok}
      end
  end

  # Fallback
  def call(call_api_name, params) do
    Logger.log(:warning, "[API] API Call does not match: #{call_api_name}, #{inspect params}")
    %{}
  end

end
