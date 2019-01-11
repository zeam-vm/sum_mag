defmodule SumMag do
  @moduledoc """
  SumMag: a meta-programming library for Hastega and Cockatorice.
  """

  @doc """
    ## Examples

    iex> [{:func, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_args
    []

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_args
    [:a]

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_args
    [:a, :b]


  """
  def parse_args(body) do
    body
    |> hd
    |> elem(2)
    |> convert_args()
  end

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
