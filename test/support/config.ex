defmodule UnbrellaTest.Config do
  def set_config! do
    Application.put_env(
      :unbrella,
      :plugins,
      plugin1: [
        module: Plugin1,
        schemas: [Plugin1.User],
        router: Plugin1.Web.Router,
        plugin: Plugin1.Plugin,
        application: Plugin1
      ],
      plugin2: []
    )
  end
end
