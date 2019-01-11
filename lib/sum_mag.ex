defmodule SumMag do
  @moduledoc """
  SumMag: a meta-programming library for Hastega and Cockatorice.
  """

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_function_name
    :null

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_function_name
    :func

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_function_name
    :add
  """
  def parse_function_name(body), do: body |> hd |> elem(0)

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_args
    []

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_args
    [:a]

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_args
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

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_do
    [{:nil, [], Elixir}]

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_do
    [{:a, [], Elixir}]

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_do
    [{:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]
  """
  def parse_do(body) do
    body
    |> tl
    |> hd
    |> hd
    |> parse_do_block()
  end

  defp parse_do_block({:do, do_body}), do: parse_do_body(do_body)

  defp parse_do_body({:__block__, _env, []}), do: []

  defp parse_do_body({:__block__, _env, body_list}) do
    body_list
    |> Enum.map(& &1
      |> parse_do_body()
      |> hd() )
  end

  defp parse_do_body(value), do: [value]

  @doc """
    ## Examples

    iex> :func |> SumMag.concat_name_nif
    :func_nif
  """
  def concat_name_nif(name) do
    name |> Atom.to_string |> Kernel.<>("_nif") |> String.to_atom
  end

end
