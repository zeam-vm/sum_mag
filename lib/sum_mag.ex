defmodule SumMag do
  @moduledoc """
  SumMag: a meta-programming library for Hastega and Cockatorice.
  """

  @doc """
  	## Examples

  	iex> [] |> SumMag.convert_args
  	[]

  	iex> [{:a, [], Elixir}] |> SumMag.convert_args
  	[:a]

  	iex> [{:a, [], Elixir}, {:b, [], Elixir}] |> SumMag.convert_args
  	[:a, :b]
  """
  def convert_args(arg_list), do: arg_list |> Enum.map(& elem(&1, 0))

end
