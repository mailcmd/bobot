defmodule Bobot.Tools do

  defmacro apply_if(value, expr, ope) do
    quote do
      if unquote(expr) do
        unquote(value) |> unquote(ope)
      else
        unquote(value)
      end
    end
  end

  def map_extract_fields(map, fields, new_map \\ [])
  def map_extract_fields(_map, [], new_map), do: new_map
  def map_extract_fields(map, [{key, title, fun} | rest], new_map) do
    map_extract_fields(
      map,
      rest,
      if map[key] do
        new_map ++ [{title, fun.(map[key])}]
      else
        new_map
      end
    )
  end
  def map_extract_fields(map, [{key, title} | rest], new_map),
    do: map_extract_fields(map, [{key, title, fn v -> v end} | rest], new_map)
  def map_extract_fields(map, [key | rest], new_map),
    do: map_extract_fields(map, [{key, key} | rest], new_map)

  @spec make_vtable(map:: map() | list()) :: [list()]
  def make_vtable(map) do
    Enum.map(map, fn {k, v} -> [k, v] end)
  end

  @spec make_htable(list_of_maps::list()) :: {list(), [list()]}
  def make_htable(list_of_maps) do
    {
      list_of_maps |> hd() |> Map.keys(),
      list_of_maps |> Enum.map(fn map -> Map.values(map) end)
    }
  end

  def table_render(table, title \\ nil, header \\ [], opts \\ [])
  def table_render(table, title, header, []) do
    TableRex.quick_render!(table, header, title)
  end
  def table_render(table, title, header, opts) do
    table = TableRex.Table.new(table, header, title)
    Enum.reduce(opts, table, fn {col, conf}, tbl ->
      TableRex.Table.put_column_meta(tbl, col, conf)
    end) |> TableRex.Table.render!()
  end

  def tables_render(tables) do
    tables
      |> Enum.map(fn table ->
        apply(Bobot.Tools, :table_render, Tuple.to_list(table))
      end)
      |> Enum.join("\n")
  end

  def render_monospaced(text) do
    "<pre>#{text}</pre>"
  end

  def get_modules(pattern \\ ~r/^Elixir\.Bobot\./) do
    :application.get_key(:bobot, :modules)
      |> elem(1)
      |> Enum.map( &(to_string(&1)) )
      |> Enum.filter( &(String.match?(&1, pattern)) )
      |> Enum.map( &(String.to_existing_atom(&1)) )
  end

  def put_inx(data, keys, value) do
    # data = %{} or non empty map
    # keys = [:a, :b, :c]
    # value = 3
    put_in(data, Enum.map(keys, &Access.key(&1, %{})), value)
  end

  def quote_string(str) do
    case eval_source_code(str) do
      {:error, _, _} = error ->
        error
      {:ok, _} ->
        ast =
          Code.eval_string("""
          quote do
            #{str}
          end
          """)
          |> elem(0)

        case ast do
          {:__block__, _, new_ast} -> new_ast
          new_ast -> [new_ast]
        end
    end
  end

  def ast_from_file(filename) do
    with {:ok, source_code} <- File.read(filename),
         {:ok, ast} <- Code.string_to_quoted(source_code) do
      ast
    else
      error -> error
    end
  end

  def ast_to_source(ast, opts \\ [])
  def ast_to_source(ast, opts) when is_tuple(ast), do: ast_to_source([ast], opts)
  def ast_to_source(ast, opts) do
    no_parens =
      Keyword.get(opts, :no_parens, [])
      |> Enum.map(fn {k,_} -> "#{k}" end)

    ast
    # |> Enum.map(&Macro.to_string/1)
    |> Enum.map( fn a ->
      a
      |> Code.quoted_to_algebra()
      |> Inspect.Algebra.format(:infinity)
      |> Kernel.++(["\n"])
    end)
    |> List.flatten()
    |> remove_parens(no_parens)
    |> IO.iodata_to_binary()
    # |> Enum.join("\n")
    # |> Code.format_string!([
    #   line_length: 150,
    #   force_do_end_blocks: true,
    #   locals_without_parens: Keyword.get(opts, :no_parens, [])
    # ])
    # |> Enum.join("")
    # |> apply_if(opts[:parens] == :remove, String.replace(~r/[\(\)]/, " "))
    |> String.trim()
  end

  def eval_source_code(str) do
    case Code.string_to_quoted(str) do
      {:error, {[{:line, nline} | _], {message, _}, line}} ->
        {:error, nline, "#{message} #{line}"}

      {:error, {[{:line, nline} | _], message, line}} ->
        {:error, nline, "#{message} #{line}"}

      {:ok, result} ->
        {:ok, result}
    end
  end

  def ast_find(ast, pattern) do
    Macro.prewalk(ast, [], fn
      {^pattern, _, _} = node, acc -> {node, acc ++ [node]}
      node, acc -> {node, acc}
    end) |> elem(1)
  end

  def ast_equals(ast1, ast2) do
    # IO.inspect ast_remove_metadata(ast1)
    # IO.inspect ast_remove_metadata(ast2)
    ast_remove_metadata(ast1) == ast_remove_metadata(ast2)
  end

  def ast_remove_metadata(ast) do
    Macro.prewalk(ast, fn
      {name, metadata, Elixir} when is_list(metadata) ->
        {name, [], nil}
      {name, metadata, args} when is_list(metadata) ->
        {name, [], args}
      {name, metadata, Elixir}  ->
        {name, metadata, nil}
      other ->
        other
    end)
  end

  def remove_parens([], _), do: []
  def remove_parens([item, "(" | list], sentencies) do
    if item in sentencies do
      [item, " "] ++ remove_parens_h(list, sentencies, 0)
    else
      [item, "("] ++ remove_parens(list, sentencies)
    end
  end
  def remove_parens([item | list], sentencies),
    do: [item] ++ remove_parens(list, sentencies)

  def remove_parens_h([], _, _), do: []
  def remove_parens_h([")" | list], sentencies, 0),
    do: [" "] ++ remove_parens(list, sentencies)

  def remove_parens_h(["(" | list], sentencies, n),
    do: ["("] ++ remove_parens_h(list, sentencies, n+1)
  def remove_parens_h([")" | list], sentencies, n),
    do: [")"] ++ remove_parens_h(list, sentencies, n-1)
  def remove_parens_h([item | list], sentencies, n),
    do: [item] ++ remove_parens_h(list, sentencies, n)

  @spec compile_file(filename::String.t) ::
        {{:ok, message::String.t}, diag::list()} | {{:error, message::String.t}, diag::list()}
  def compile_file(filename) do
    {{result, message}, real_errors} =
      Code.with_diagnostics(fn ->
        try do
          {module, _} = filename
            |> Code.compile_file()
            |> hd

          set_module_md5(module, source_file_md5(filename))
          {:ok, "File #{filename} compiled OK!"}
        rescue
          error -> {:error, "#{inspect error}"}
        end
      end)

      case {{result, message}, real_errors} do
        {{:ok, message}, _} ->
          {:ok, message}

        {{:error, message}, diagnostic} ->
          real_error =
            diagnostic
            |> Enum.filter(&(&1.severity == :error))

          real_error =
            if real_error == [] do
              %{message: message}
            else
              hd(real_error)
            end

          diagnostic_message = real_error[:message]
          nline =
            case real_error[:position] do
              {nline, _} -> nline
              nline -> nline
            end

          {{:error, message}, %{nline: nline, message: diagnostic_message}}
      end
  end

  def source_file_md5(filename) do
    filename
      |> File.read!()
      |> Code.string_to_quoted()
      |> ast_remove_metadata()
      |> :erlang.term_to_binary()
      |> :erlang.md5()
  end

  def set_module_md5(module, md5) do
    :dets.insert(:static_db, {{:module, module}, md5})
  end

  def get_module_md5(module) do
    case :dets.lookup(:static_db, {:module, module}) do
      [] -> nil
      [{_, md5}] -> md5
    end
  end

  def channel_subscribe(channel, subject) do
    IO.inspect :dets.insert(:static_db, {{:channel, channel}, subject})
  end

  def channel_unsubscribe(channel, subject) do
    :dets.delete_object(:static_db, {{:channel, channel}, subject})
  end

  def task_every_add(bot_module, channel, quoted_pattern, quoted_func) do
    # bot = bot_module.__info__(:attributes)[:bot_name] |> hd()
    :ets.insert(:volatile_db, {:task, bot_module, channel, quoted_pattern, quoted_func})
  end

end
