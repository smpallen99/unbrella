# Unbrella

Unbrella is a library to help Phoenix designers build an application that can be extended with plugins.

Elixir's umbrella apps work will to package independent apps in a common project. Once way dependencies work wll with umbrella apps. However, if you need to share code bidirectionaly between two apps, you need a different solution.

Unbrella is designed to allow plugins to extend the schema of a model defined in the main project. It allow allows inserting routers and plugin configuration.

> This project is a work in progress. I'm using it in a project that I have not completed yet.

## Installation

```elixir
def deps do
  [{:unbrella, github: "smpallen99/unbrella"}]
end
```

## Usage

### Project Structure

Plugs are located in the plugins folder under your project's root folder. This allows them to be compiled with your project so code can be shared between the main app and the plugis.

```
my_app
├── config
├── lib
├── plugins
│   ├── my_plugin
│   │   ├── config
│   │   │   └── config.exs
│   │   └── lib 
│   ├── another_plugin
# ...
```

### Anatomy of a Plugin

A plug uses a very simpilar project structure to an other Elixir or Phoenix app.

Plugin configuration is done through a `plugins/my_plugin/config/config.exs` file. 

TBD: Finish this page.

## License

`unbrella` is Copyright (c) 2017 E-MetroTel

The source is released under the MIT License.

Check [LICENSE](LICENSE) for more information.


## Development

`.tool-versions` selects Elixir **1.20.4-otp-29** and Erlang **29.1.2**.
The project targets Phoenix **1.8.15**, Phoenix Ecto **4.7.0**, and Ecto SQL
**3.14.0** (Ecto **3.14.2** in the lockfile).

```sh
asdf install
mix deps.get
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix coveralls
mix dialyzer
mix credo --strict
mix format --check-formatted
```

Tests compile real schema extensions, changesets, hooks, and Phoenix routers.
Migration and rollback tests collect main and plugin migration modules and exercise
Ecto's task lifecycle with an injected migrator and a test repository. They do not
connect to a database or execute SQL. Asset and seed tests use temporary directories.
Tests that change application configuration or the working directory run serially.

Plugins are registered through application configuration and compiled with their
host project. After adding a plugin, run `mix do clean, compile` in that project to
establish all compile-time links. Use `mix unbrella.migrate` to include plugin
migrations.

Fresh builds may emit upstream ExCoveralls warnings, Phoenix Ecto's deprecated
xref configuration warning, and FileSystem's legacy macOS linker search-path
warnings. The project's own compilation and tests pass with warnings as errors.

`mix unbrella.new` remains an unfinished generator that validates and prints a name;
it does not create a plugin scaffold.
