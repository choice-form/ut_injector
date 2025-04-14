defmodule UtInjector do
  defmacro __using__(opts) do
    app = Keyword.fetch!(opts, :app)

    quote do
      def registry do
        case Application.get_env(unquote(app), __MODULE__) do
          [{key, _} | _] = reg when is_atom(key) ->
            reg |> Keyword.fetch!(:registry) |> Map.new()

          _ ->
            raise "#{inspect(__MODULE__)}: the registry is empty or not set. Please define a registry as follow:\n\n" <>
                    """
                    # In config/config.exs or other config files
                    config #{inspect(unquote(app))}, #{inspect(__MODULE__)},
                      registry: %{
                        xxx_module1: XxxModule1,
                        xxx_module2: XxxModule2
                      }
                    """
        end
      end

      def fetch!(key) do
        case registry() |> Map.fetch(key) do
          {:ok, val} -> val
          :error -> raise "#{inspect(__MODULE__)}: key #{inspect(key)} not found in registry"
        end
      end

      @doc """
      以生成函数的形式注入 key 相关的事物

      ## 可选参数

      - `as` - 函数名，默认跟 key 同名
      - `public` - 是否以公共函数的形式注入。默认值 `false`
      """
      @spec inject_function(key :: atom(), opts :: [as: atom()]) :: any()
      defmacro inject_function(key, opts \\ []) do
        fn_name = opts[:as] || key
        public? = opts[:public] || false
        injector = __MODULE__

        quote do
          if unquote(public?) do
            @doc "Inject module registered as key #{inspect(unquote(key))}"
            @spec unquote(fn_name)() :: module()
            def unquote(fn_name)() do
              unquote(injector).fetch!(unquote(key))
            end
          else
            @spec unquote(fn_name)() :: module()
            defp unquote(fn_name)() do
              unquote(injector).fetch!(unquote(key))
            end
          end
        end
      end

      @doc """
      以生成宏的形式注入 key 相关的事物

      ## 可选参数

      - `as` - 函数名，默认跟 key 同名
      - `public` - 是否以公共宏的形式注入。默认值 `false`
      """
      defmacro inject_macro(key, opts \\ []) do
        fn_name = opts[:as] || key
        public? = opts[:public] || false
        mod = __MODULE__.fetch!(key)

        quote do
          Module.put_attribute(__MODULE__, unquote(fn_name), unquote(mod))

          if unquote(public?) do
            @doc "Inject module #{inspect(unquote(mod))} registered as key #{inspect(unquote(key))}"
            defmacro unquote(fn_name)() do
              unquote(mod)
            end
          else
            defmacrop unquote(fn_name)() do
              unquote(mod)
            end
          end
        end
      end

      defmacro __using__(opts) do
        injector = __MODULE__

        quote do
          require unquote(injector)

          import unquote(injector),
            only: [
              inject_function: 1,
              inject_function: 2,
              inject_macro: 1,
              inject_macro: 2
            ]
        end
      end
    end
  end
end
