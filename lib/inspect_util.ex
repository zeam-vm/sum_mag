defmodule SumMag.Opt do
  @syntax_colors [atom: :cyan, number: :yellow]

  def inspect(term) do
    term
    |> IO.inspect(syntax_colors: @syntax_colors)
  end

  def inspect(term, label: label) when is_binary(label) do
    [{:"#{label}", term}]
    |> IO.inspect(syntax_colors: @syntax_colors)

    term
  end
end