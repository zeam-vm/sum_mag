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
    |> Opt.inspect
    |> get_func
    |> Enum.map(& &1 |> to_keyword |> map_map_fusion ) 
    |> Enum.map(& &1 |> to_ast)
    |> decompose
    |> Opt.inspect
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
  sectionは次のような形です.\n
  section is following type  
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
  Get section of definition\n
  """
  def get_section([{_func_name, section, _body}]), do: section

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
      {:|>, meta_data1,
        [
          {:|>, meta_data2, body},
          right
        ]
      }) do 

      left = {:|>, meta_data1, body}
      enum_map_with_arg = left |> analysis 

      func = right |> get_func_from_enum_map

      fused_proc = fusion_expr(
        enum_map_with_arg |> get_func_from_enum_map, 
        func)

      section = enum_map_with_arg 
      |> get_func_from_enum_map 
      |> get_section

      arg = enum_map_with_arg |> get_arg
      enum_map_pos = enum_map_with_arg |> get_enum_map_pos
      fused_proc = [{:&, section, fused_proc}]

      {:|>, meta_data2, 
      [ 
        arg, 
        enum_map_pos |> Tuple.append(fused_proc)
      ]}
  end 

  defp analysis(
    {:|>, _meta_data1,
      [ 
        { atom, meta_data2, nil}, right]
    }) do
    [{atom, meta_data2, nil} , right ]
  end

  defp analysis(expr), do: expr

  defp fusion_expr(
    [{atom1, meta1, 
      [
        {:&, arg_meta1, [1]},  
        expr_or_value1
      ]
    }], 
    [{atom2, meta2, 
      [
        {:&, arg_meta2, [1]},  
        expr_or_value2
      ]
    }]) do

    [{atom2, meta2,
      [
        {atom1, meta1,[
          {:&, [arg_meta1, arg_meta2], [1]},  
          expr_or_value1
        ]},
        expr_or_value2
      ]
    }]
  end

  @doc """
  
  
  """
  def get_enum_map_pos(
    [ 
      _,
      { {:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos1, _ }
    ])
    do
      { {:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos1}
  end

  @doc """
  
  
  """
  def get_enum_map_pos(
    { {:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos, 
          [ 
            {:&, _pos, _func}
          ]
    })
    do
      {{:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos}
  end

  @doc """
  
  
  """
  def get_arg(
    [{arg, meta, nil},
    {{:., dot_pos, [{:__aliases__, dot_pos, [:Enum]}, :map]}, pos, 
      [{:&, pos, _func}]
    }]) do
    {arg, meta, nil}
  end
  
  @doc """
  
  collection
  |> Enum.map(bar) <- here
  |> Enum.map(hoge)
  |> Enum.map(foo) 

  """
  def get_func_from_enum_map(
    [_collections, {{:., _, [ {:__aliases__, _, [:Enum] }, :map]}, _, 
      [{:&, _, function}]
    }]) do
    function 
    # |> Opt.inspect(label: "先頭")
  end  

  @doc """
  
  collection
  |> Enum.map(bar)
  |> Enum.map(hoge)
  |> Enum.map(foo) <- here

  """
  def get_func_from_enum_map(
    { {:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, 
          [ 
            {:&, _, function}
          ]
    }) do
    function 
    # |> Opt.inspect(label: "末尾")
  end
end