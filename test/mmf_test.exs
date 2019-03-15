
defmodule SumMag.MMF_Test do
  use ExUnit.Case

  test "map map fusion's result" do
    assert( [4, 6, 8] = [1, 2, 3] |> SumMag.MMF.Sample.func_name ) 
  end
end
