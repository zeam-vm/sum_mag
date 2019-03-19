defmodule SumMag.MMF do
  alias Locale.En, as: Locale
  alias SumMag.MMF.Opt 

  @func_ast Locale.func_ast
  @func_name Locale.func_name

  @moduledoc """
  Map/Map Fusion for Elixir
  
  # Map/Map fusion
  Map/Map Fusion is a way of optimized expression.
  
  ## before
  ```elixir
  list
  |> Enum.map(& &1 |> foo)
  |> Enum.map(& &1 |> bar)
  ```

  # after
  ```elixir
  list
  |> Enum.map(& &1 |> foo |> bar)
  ```
  """
  defmacro defmmf clause do
    clause
    |> Opt.inspect(label: "before")
    |> get_func
    |> Enum.map(& &1 |> to_keyword |> map_map_fusion ) 
    |> Enum.map(& &1 |> to_ast)
    |> decompose
    |> Opt.inspect(label: "after")
  end

  @doc """
    iex> quote do( defmodule M do: def func do: 0)
    
  """

  def get_func([ do: { :__block__, [], []    } ]), do: []
  def get_func([ do: { :__block__, [], funcs } ]), do: funcs
  def get_func([ do: func]), do: [func] 

  @doc """
  関数の実装部を取り出します\n
  Take a main process of function\n
  posは次のような形です.\n
  pos is following type  
  - [line: 10]  
  - [context: Elixir, import: Kernel]

  ## Params

  ## Example
  iex> {:def, [], [:func_name], [] , arg}, expr}
  

  """
  def to_keyword({ :def, meta, [{func_name, meta, args}, expr] }) do
    [ 
      { @func_name, func_name},
      { @func_ast,  expr |> Keyword.get(:do)},
      { :meta, meta},
      { :args, args}
    ] 
  end

  def decompose([ func | tl] = funcs) do
    case tl do
      [] -> [ do: func]
      _ -> [ do: { :__block__, [], funcs } ]
    end
  end


  # transform keyword-list into AST
  def to_ast([ 
      { @func_name, func_name},
      { @func_ast,  expr},    
      { :meta, meta},
      { :args, args}
    ]) do
    {:def, meta, [{func_name, meta, args}, [ do: expr ] ]}
  end

  @doc """
  定義箇所( [line: ] )の取り出し\n
  Get pos of definition\n
  """
  def get_pos([{_func_name, pos, _body}]), do: pos

  @doc """
  
  """
  def map_map_fusion([ 
      { @func_name, func_name},
      { @func_ast,  expr},    
      { :meta, meta},
      { :args, args}
    ]) do 
    [
      { @func_name, func_name},
      { @func_ast, expr |> analysis},
      { :meta, meta},
      { :args, args}
    ]
  end
  
  # ASTを再帰的に走査して，パイプライン演算子のネストを検知する\n
  # 最低2個連なっていれば，Map/Map Fusionを試みる\n
  # find nests of pipe line operator by recursive.\n
  # If ast have more than 2 nest layer, try optimizing expressions with Map/Map Fusion\n
  defp analysis(
      {:|>, meta1,
        [
          {:|>, meta2, early}, late
        ]
      }) do 

      inner_branch = early |> enum_map_to_key |> Opt.inspect(label: "inner")
      branch2      = late  |> enum_map_to_key |> Opt.inspect(label: "outer")

      fused_proc = fusion_func( inner_branch[:func], branch2[:func])

      {:|>, [meta1, meta2], [
        inner_branch[:collection],
        inner_branch[:enum_map] |> Tuple.append(fused_proc)
      ]}
  end 

  defp analysis(expr), do: expr

  # defp analysis({:|>, _, literal}, acc) do
  #   case literal do
  #     [ {:|>, _, _}, _child ] -> 
  #       literal |> IO.inspect(label: "literal")
  #       # buf = child |> 
  #      _  -> 
  #       literal |> IO.inspect(label: "literal")
  #   end
  # end  

  defp fusion_func(
    [{atom1, meta1, 
      [
        {:&, arg_meta1, [1]},  
        expr1
      ]
    }], 
    [{atom2, meta2, 
      [
        {:&, arg_meta2, [1]},  
        expr2
      ]
    }]) do

    fused_proc = [{atom2, meta2,
      [
        {atom1, meta1,[
          {:&, [arg_meta1, arg_meta2], [1]},  
          expr1
        ]},
        expr2
      ]
    }]

    [{:&, [meta1, meta2], fused_proc}]
  end
  
  def enum_map_to_key(
    [collection, {{:., meta, [ {:__aliases__, map_meta, [:Enum] }, :map]}, enum_meta, 
      [{:&, func_meta, function}]
    }]) do
    [
      {:collection,collection},
      {:enum_map,  {{:., meta, [ {:__aliases__, map_meta, [:Enum] }, :map]}, enum_meta}},
      {:func_meta, func_meta},
      {:func,      function}
    ]
  end  

  def enum_map_to_key(
   {{:., meta, [ {:__aliases__, map_meta, [:Enum] }, :map]}, enum_meta, 
      [{:&, func_meta, function}]
    }) do
    [
      {:enum_map,  {{:., meta, [ {:__aliases__, map_meta, [:Enum] }, :map]}, enum_meta}},
      {:func_meta, func_meta},
      {:func,      function}
    ]
  end  
end