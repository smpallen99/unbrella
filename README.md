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

