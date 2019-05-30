defmodule SumMag.MMF.Sample do
  require SumMag.MMF
  import SumMag.MMF

  defmmf do
    def mmfed(list) do
      list
      |> Enum.map(& &1 + 1)
      |> Enum.map(& &1 * 2)
      # |> Enum.map(& &1 / 3)
    end

    def test, do: 0
  end

  def pure(list) do
    list
    |> Enum.map(& &1 + 1)
    |> Enum.map(& &1 * 2)
  end
end