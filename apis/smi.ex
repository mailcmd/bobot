import Bobot.DSL.Base

defapi :smi do


  @url "http://190.1.0.3:7531/smi/"
  # @url "http://186.189.240.9:3580/smi/"
  @username "vianet"
  @password "lowland"

  @impl true
  defcall :authenticate, _muid do
    %{authentication: :ok}
  end

  defcall :find_user, message do
    url = "#{@url}def.get_dev_info.php?action=findUser&decfile=&devkey=&fname=undefined&ifindex=&json=1&code=#{message}"
      |> URI.encode()
      |> URI.encode(&(&1 != ?#))

    result = Tesla.client([
      {Tesla.Middleware.BasicAuth, %{username: @username, password: @password}}
    ]) |> Tesla.get(url)

    with {:ok, %Tesla.Env{body: body}} <- result,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do

      case json do
        %{oltdata: oltdata} when is_binary(oltdata) ->
          user_data =
            case Jason.decode(oltdata, keys: :atoms) do
              {:ok, data} -> data
              _ -> %{}
            end
          %{
            result_type: :ftth,
            data: process_ftth(user_data)
          }

        %{cmtsdata: cmtsdata} when is_binary(cmtsdata) ->
          user_data =
            case Jason.decode(cmtsdata, keys: :atoms) do
              {:ok, data} -> data
              _ -> %{}
            end
          signal = hd(json[:item])

          %{
            result_type: :docsis,
            data: process_docsis(user_data, "#{signal[:url]}?#{signal[:params]}")
          }

        _ -> %{result_type: :error}
      end
    else
      _ -> %{result_type: :error}
    end
  end



  ################################################################################################
  ## PRIVATE TOOLS                                                                              ##
  ################################################################################################
  defp process_ftth(user) do
    name = user[:denominacion_cli]
    address = "#{user[:calle_loc]} #{user[:numero_loc]}"
    table1 = user
      |> map_extract_fields([
        {:descripcion_pack, "Pack"},
        {:estado_pack, "Estado"},
        {:modelo_ont, "Modelo ONT"},
        {:mac_ont, "MAC"},
        {:serial_ont, "Serial number"},
        {:name, "OLT"}
      ])
      |> make_vtable()

    fun = fn
      v when is_binary(v) -> "#{String.to_integer(v)/100} dBm"
      v when is_integer(v) and v < 10000 -> "#{v/100} dBm"
      _ -> "--"
    end

    table2 = user
      |> map_extract_fields([
        {:OltRxOntPower, "OltRxOntPower", fun},
        {:RxPower, "RxPower", fun},
        {:TxPower, "TxPower", fun},
        {:catv_ont, "CATV", fn st -> st == "1" && "Habilitado" || "--" end},
        {:CatvAdminStatus, "CATV Ad.State", fn st -> st == "1" && "Online" || "Offline" end},
        {:CatvOnlineStatus, "CATV Op.State", fn st -> st == "1" && "Online" || "Offline" end},
        {:CATVRxPower, "CATVRxPower", fun}
      ])
      |> make_vtable()

    [
      {table1, "#{name} (#{address})", [], []},
      {table2, "Señal", [], [{1, align: :right}]}
    ] |> tables_render()
      |> render_monospaced()
  end

  defp process_docsis(user, signal_url) do
    IO.inspect(user, limit: :infinity)
    name = user[:denominacion_cli]
    address = "#{user[:calle_loc]} #{user[:numero_loc]}"
    table1 = user
      |> map_extract_fields([
        {:descripcion_pack, "Pack"},
        {:estado_efectivo_ser, "Estado", &HtmlSanitizeEx.strip_tags/1},
        {:modelo_cm, "Modelo CM"},
        {:mac_cm, "MAC"},
        {:docsIfCmtsCmStatusValue, "Estado Reg.", &HtmlSanitizeEx.strip_tags/1},
        {:name, "CMTS"}
      ])
      |> make_vtable()
      |> table_render("#{name} (#{address})", [])
      |> render_monospaced()

    tables2 =
      if user[:docsIfCmtsCmStatusValue] =~ "registrationComplete" do
        case docsis_signal(signal_url) do
          :error ->
            "Lo siento, no pude obtener los valores de señal 😢"

          tables ->
            tables
              |> tables_render()
              |> render_monospaced()
        end
      else
        ""
      end

    "#{table1}#{tables2}"
  end

  defp docsis_signal(url) do
    url = "#{@url}#{url}&json=1"
      |> URI.encode()
      |> URI.encode(&(&1 != ?#))

    result = Tesla.client([
        {Tesla.Middleware.BasicAuth, %{username: @username, password: @password}}
      ])
      |> Tesla.get(url)

    with {:ok, %Tesla.Env{body: body}} <- result,
         {:ok, signals} <- Jason.decode(body, keys: :atoms) do

      down_table = {
        signals[:down]
          |> Enum.map(fn {_, sig} ->
            [sig[:ifName], "#{sig[:docsIfSigQSignalNoise]} dBm", "#{sig[:docsIfDownChannelPower]} dBmV"]
          end),
        "Calidad de Señal Downstream",
        ["Down", "SNR", "Power"],
        [{1, align: :right}, {2, align: :right}]
      }

      up_table = {
        signals[:up]
          |> Enum.map(fn {_, sig} ->
            [sig[:ifName], "#{sig[:docsIf3CmtsCmUsStatusSignalNoise]} dBm", "#{sig[:docsIf3CmStatusUsTxPower]} dBmV"]
          end),
        "Calidad de Señal Upstream",
        ["Down", "SNR", "Power"],
        [{1, align: :right}, {2, align: :right}]
      }

      [down_table, up_table]
    else
      _ ->
        :error
    end
  end


end
