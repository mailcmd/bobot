defmodule Bobot.API.Test do
  use Bobot.API

  @impl true
  def call(:is_first_contact, phone) when is_integer(phone) and phone > 0 do
    %{
      first_contact: false,
      menu: ["Terrada 1254", "Salta 98", "Zelarrayán 279", "San Martín 133"],
      correct_item: 3,
      id: 12528
    }
  end
  def call(:is_first_contact, _) do
    %{
      first_contact: true,
      menu: [],
      correct_item: -1,
      id: -1
    }
  end

  def call(:client_status, _id) do
    %{ status: :suspend }
  end

  def call(:addresses_menu, id) do
    %{
      menu: ["Terrada 1254", "Salta 98", "Zelarrayán 279", "San Martín 133"],
      correct_item: 3,
      id: id
    }
  end

  def call(:save_interaction, _params) do
    %{}
  end

  # Fallback
  def call(call_api_name, params) do
    raise("API Call does not match: #{call_api_name}, #{inspect params}")
  end

end
