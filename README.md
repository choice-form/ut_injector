# Ut Injector

运行时依赖注入器。本质上它只提供一个全局注册和寻找机制，注入的东西是什么由开发者决定。

实践上多用于注入定义好 behaviour 的模块，并为 test 和其他环境注入不同的实现，避免通过函数参数传参注入导致的 “每层都要带注入参数” 的问题。

## 安装

把 `ut_injector` 加入 `mix.exs` ：

```elixir
def deps do
  [
    {:ut_injector, git: "git@github.com:choice-form/ut_injector.git", tag: "v0.1.0"}
  ]
end
```

## 使用

**可选**，把 `ut_injector` 的 DSL 加入 `.formatter.exs` ：

```elixlr
# in .formatter.exs
[
  import_deps: [:ut_injector],
]
```

在你的 app 中定义 `Injector` 模块。如果是 umbrella app ，你可能需要定义多个 `Injector` ，这取决于你是否要进行 app 之间的依赖隔离。

```elixir
defmodule YourApp.Injector do
  use UtInjector, app: :your_app
end
```

在 config 文件中注册要注入的东西，每个被注入的东西需要唯一的 key 。所谓被注入的东西由你决定。

下面以 “为 test 其他环境注入不同的模块” 的场景举例：

```elixir
# in config/config.exs
config :your_app, YourApp.Injector,
  registry: %{
    mod_1: YourApp.Mod1,
    mod_2: YourApp.Mod2
  }

# in config/test.exs
config :your_app, YourApp.Injector,
  registry: %{
    mod_1: YourApp.Mod1Mock,
    mod_2: YourApp.Mod2Mock
  }
```

**可选**，为了保证实际模块和 Mock 模块的行为一致，推荐定义 behaviour ，并用 Mox & Hammox 生成测试模块：

```elixir
# in your_app/lib/your_app/mod_1.ex 中
defmodule YourApp.Mod1Intf do
  @callback some_func() :: :ok
end

defmodule YourApp.Mod1 do
  @behaviour YourApp.Mod1Intf

  @impl true
  def some_func, do: :ok
end

# in test/support/mocks.ex
Hammox.defmock(YourApp.Mod1Mock, for: YourApp.Mod1Intf)
```

在需要注入依赖的模块中使用。实践中可以为被注入的模块和其测试都 `use` injector ：

```elixir
defmodule YourApp.TopLevelMod do
  use YourApp.Injector

  # 这会为该模块生成 mod_1/0 函数，返回值是被注入的东西
  inject_function :mod_1

  # 也可以修改生成的函数名
  inject_function :mod_2, as: :mod_two

  def hello do
    mod_1().some_func()
    mod_two().some_func()
  end
end
```
