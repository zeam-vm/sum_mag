defmodule SumMag.AST do
  defmacro is_literal(value) do
    quote do
      is_list(unquote(value))
      or is_number(unquote(value))
      or is_atom(unquote(value))
      or is_list(unquote(value))
      or is_tuple(unquote(value)) and tuple_size(unquote(value)) == 2
    end
  end
end

defmodule SumMag.MMF do
  require SumMag.AST
  import SumMag.AST
  @section "################"

  @moduledoc"""
  Map/Map Fusion for Elixir
  
  # Map/Map fusion
  Map/Map Fusion is a way of optimized expression.
  
  ## before
  ```elixir
  list
  |> Enum.map(foo)
  |> Enum.map(bar)
  ```

  # after
  ```elixir
  list
  |> Enum.map(& &1 |> foo |> bar)
  ```
  """
  defmacro defmmf clause do
    clause
    |> IO.inspect
    |> Macro.to_string
    |> IO.inspect(label: "original_clause")

    [do: {:def, section, [function_name, process]}] = clause 

    fused_func_list = clause
    |> Keyword.get(:do, nil) 
    # { :__block__, [], 関数定義部}から関数定義部をとる(func_list) 
    |> get_func_section
    # func_listをEnum.mapでmap/map fusionする(flowで高速化する?)
    |> Enum.map(&  
      &1 
      |> parse 
      # |> IO.inspect(label: "before_fusion")
      |> map_map_fusion
      # |> IO.inspect(label: "after_fusion")
    ) # 全てfusionできるかはわからんのでリストで返す
    |> hd # 結果に[]がつくので一旦書いている行

    # process |> IO.inspect(label: "origin_function")
    # fused_func_list |> IO.inspect(label: "fused_function")

    fused_clause = [do: fused_func_list]

    [do: {:def, section, [function_name, fused_clause]}]
    |> Macro.to_string
    |> IO.inspect(label: "generated_clause")
  end

  @doc"""
  関数の実装部を取り出します\n
  Take a main process of function\n
  sectionは次のような形です.\n
  section is following type  
  - [line: 10]  
  - [context: Elixir, import: Kernel]  
  """
  def parse({:def, section, [function_name, process]}) do
    process |> Keyword.get(:do)
  end

  def parse({:defp, section, [function_name, process]}) do
    process |> Keyword.get(:do)
  end

  @doc"""
  関数がないパターン\n
  No function  \n
  """
  def get_func_section({:__block__, _e, []}, _env), do: []
  
  @doc"""
  関数が1つだけあるパターン\n
  One function\n
  """
  def get_func_section(body), do: [body]

  @doc"""
  関数が複数あるパターン\n
  Many functions\n
  """
  def get_func_section({:__block__, _e, body_list}) do
    body_list
  end

  @doc"""
  定義箇所( [line: ] )の取り出し\n
  Get section of definition\n
  """
  def get_section([{_func_name, section, _body}]), do: section

  @doc"""
  関数名の取り出し\n
  Get function name\n
  """
  defp parse_function_name(body) do 
    SumMag.parse_function_name(body, [])
  end

  @doc"""
  
  """
  def map_map_fusion(func_list) do
    func_list |> analysis
  end

  @doc"""
  ASTを再帰的に走査して，パイプライン演算子のネストを検知する\n
  最低2個連なっていれば，Map/Map Fusionを試みる\n
  find nests of pipe line operator by recursive.\n
  If ast have more than 2 nest layer, try optimizing expressions with Map/Map Fusion\n
  """
  defp analysis(
      {:|>, _meta_data1,
        [
          {:|>, _meta_data2, body},
          right
        ]
      }) do 


      left = {:|>, _meta_data1, body}
      # IO.inspect "map1"
      enum_map_with_arg = left |> analysis 
      # |> IO.inspect

      # IO.inspect "map2"
      func = right |> get_func_from_enum_map 
      # |> IO.inspect

      fused_proc = fusion_expr(
        enum_map_with_arg |> get_func_from_enum_map, 
        func)
      # |> IO.inspect

      @section |> IO.inspect

      section = enum_map_with_arg 
      |> get_func_from_enum_map 
      |> get_section

      arg = enum_map_with_arg |> get_arg
      enum_map_pos = enum_map_with_arg |> get_enum_map_pos
       # |> IO.inspect(label: "enum_map_pos")
      fused_proc = [{:&, section, fused_proc}]

      {:|>, _meta_data2, 
      [ 
        arg, 
        enum_map_pos |> Tuple.append(fused_proc)
      ]}
      # |> IO.inspect
  end 

  @doc"""
  
  
  """
  defp analysis(
    {:|>, _meta_data1,
    [ 
      {_atom, meta_data2, nil},
      _right]
    }) do
    [{_atom, meta_data2, nil} , _right ]
  end

  @doc"""

  
  """
  defp fusion_expr(
    [{operator1, _section1, 
      [
        {:&, _section2, [1]},  
        expr_or_value1
      ]
    }], 
    [{operator2, _section3, 
      [
        {:&, _section4, [1]},  
        expr_or_value2
      ]
    }]) do

    # "map/map fusion" |> IO.inspect
    [{operator2, _section1,
      [
        {operator1, _section1,[
          {:&, _section1, [1]},  
          expr_or_value1
        ]},
        expr_or_value2
      ]
    }]
  end

  @doc"""
  
  
  """
  def get_enum_map_pos(
    [ {_arg, _e, nil},
      { 
        {:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos1, 
          [ 
            {:&, pos2, function}
          ]
        }])
    do
      { {:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos1}
  end

  @doc"""
  
  
  """
  def get_enum_map_pos(
    { {:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos, 
          [ 
            {:&, _pos, function}
          ]
    })
    do
      {{:., dot_pos1, [{:__aliases__, dot_pos2, [:Enum]}, :map]}, pos}
  end

  @doc"""
  
  
  """
  def get_arg(
    [{arg, e, nil},
    {{:., _dot_pos, [{:__aliases__, _dot_pos, [:Enum]}, :map]}, _pos, 
      [{:&, _pos, function}]
    }]) do
    {arg, e, nil}
  end
  
  @doc"""
  
  
  """
  def get_func_from_enum_map(
    [{_arg, _e, nil},
    {{:., _dot_pos, [{:__aliases__, _dot_pos, [:Enum]}, :map]}, _pos, 
      [{:&, _pos, function}]
    }]) do
    function
  end  

  @doc"""
  
  
  """
  def get_func_from_enum_map(
    { {:., _dot_pos, [{:__aliases__, _dot_pos, [:Enum]}, :map]}, _pos, 
          [ 
            {:&, _pos, function}
          ]
    }) do
    function
  end
end

defmodule SumMag.MMF.Sample do
  require SumMag.MMF
  import SumMag.MMF

  defmmf do
    def test1(list) do
      list
      |> Enum.map(& &1 + 2)
      |> Enum.map(& &1 * 1)
    end
  end

  def test2(list) do
      list
      |> Enum.map(& &1 + 2)
      |> Enum.map(& &1 * 1)
    end

end
