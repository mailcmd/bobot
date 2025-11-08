defmodule Bobot.Tools do
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
    Code.eval_string("""
    quote do
      #{str}
    end
    """) |> elem(0)
  end

end
