defmodule Bobot.Parser do
  def parse(value, :string), do: value

  def parse(value, :integer) do
    case Integer.parse(value) do
      :error -> :error
      {val, _} -> val
    end
  end

  def parse(value, :float) do
    case Float.parse(value) do
      :error -> :error
      {val, _} -> val
    end
  end
end
