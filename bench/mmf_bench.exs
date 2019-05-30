defmodule MMFBench do
	use Benchfella

	@range 1..10_000_000

	bench "pure elixir", [data: @range ] do
		data
		|> SumMag.MMF.Sample.pure
	end

	bench "map/map fusinon", [data: @range ] do
		data
		|> SumMag.MMF.Sample.mmfed
	end

end