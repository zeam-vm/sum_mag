defmodule Hnum do
	defmacro summon clause do
		clause
		|> IO.inspect(label: "original")
		|> Macro.prewalk(
			[],
			fn 
				( {:|>, _,
					[
						{{:., _, [{:__aliases__, _, [:Enum]}, :zip]}, _, _arg},
						right
					]},acc ) -> { right |> IO.inspect(label: "true"), acc}
				(other, acc) -> {other, acc}
			end)
		|> IO.inspect(label: "acc")
		
		clause
	end
end



defmodule HnumTest do
	require Hnum

	Hnum.summon do
		def dot(a, b) do
			Enum.zip(a, b)
			|> Enum.map(fn {a, b} -> a * b end)
		end
	end

end
