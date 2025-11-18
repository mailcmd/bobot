import Bobot.DSL.Base

defapi :test do

  defcall :is_first_contact, phone do
    %{
      first_contact: false,
      menu: ["Terrada 1254", "Salta 98", "Zelarrayán 279", "San Martín 133"],
      correct_item: 3,
      id: 12528
    }
  end

  defcall :is_first_contact, _ do
    %{
      first_contact: true,
      menu: [],
      correct_item: -1,
      id: -1
    }
  end

  defcall :client_status, _id do
    %{ status: :suspend }
  end

  defcall :addresses_menu, id do
    %{
      menu: ["Terrada 1254", "Salta 98", "Zelarrayán 279", "San Martín 133"],
      correct_item: 3,
      id: id
    }
  end

  defcall :save_interaction, _params do
    %{}
  end

end
