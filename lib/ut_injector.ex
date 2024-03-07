defmodule UtInjector do
  defmacro __using__(opts) do
    app = Keyword.fetch!(opts, :app)

    quote do
      def registry do
        case Application.get_env(unquote(app), __MODULE__) do
          [{key, _} | _] = reg when is_atom(key) ->
            Keyword.fetch!(reg, :registry)

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

      defmacro inject_function(key, opts \\ []) do
        fn_name = opts[:as] || key
        injector = __MODULE__

        quote do
          @doc """
          Inject module registered as key #{inspect(unquote(key))}
          """
          @spec unquote(fn_name)() :: module()
          def unquote(fn_name)() do
            unquote(injector).fetch!(unquote(key))
          end
        end
      end

      defmacro __using__(opts) do
        injector = __MODULE__

        quote do
          require unquote(injector)
          import unquote(injector), only: [inject_function: 1, inject_function: 2]
        end
      end
    end
  end

  # defmacro inject(name) do
  #   quote bind_quoted: [name: name] do
  #     mod =
  #       Application.compile_env!(:txwf, TXWF.Injector)
  #       |> Keyword.fetch!(name)
  #
  #     Module.put_attribute(__MODULE__, name, mod)
  #   end
  # end
  #
  # def fetch_mod!(name) do
  #   case Keyword.fetch(mods(), name) do
  #     {:ok, mod} -> mod
  #     :error -> raise "Can't inject module which registered as #{inspect(name)}"
  #   end
  # end
  #
  # defp mods do
  #   Application.fetch_env!(:txwf, __MODULE__)
  # end
  #
end
