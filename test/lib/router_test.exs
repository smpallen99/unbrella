defmodule Unbrella.RouterTest do
  use ExUnit.Case

  defmodule TestWeb.Router do
    use Unbrella.Router

    scope "/", TestWeb do
      pipe_through(:browser)
      get("/", HomeController, :index)
      get("/:id", HomeController, :show, option: :first)
    end

    scope "/one", TestWeb do
      pipe_through([:browser, :api])
      pipe_through(:other)
      get("/", OneController, :index)
      get("/:id", OneController, :show)
      post("/", OneController, :create)
      put("/:id", OneController, :update)
      patch("/:id", OneController, :update)
      delete("/:id", OneController, :delete)
    end

    scope "/", TestWeb do
      pipe_through(:browser)
      resources("/account", AccountController)
      resources("/user", UserController, only: [:show], singleton: true)
    end

    scope "/top", TestWeb do
      pipe_through(:other)

      resources "/", TopController, only: [:index, :show] do
        resources("/nested", NestedController, only: [:show])

        resources "/three", ThreeController do
          resources("/four", FourController)
        end
      end
    end

    scope path: "/api/v1", as: :api_v1, alias: API.V1 do
      get("/pages/:id", PageController, :show)
    end

    scope "/api/v1", API.V1, as: :api_v1 do
      get("/pages/:id", PageController, :show)
    end
  end

  test "supports root scope" do
    expected = %{
      scope: {"/", TestWeb},
      pipe_through: [:browser],
      matches: [
        {:get, "/", HomeController, :index, []},
        {:get, "/:id", HomeController, :show, [option: :first]}
      ],
      resources: []
    }

    [scope1 | _] = TestWeb.Router.get_scopes()
    assert scope1 == expected
  end

  test "supports non root scope" do
    expected = %{
      scope: {"/one", TestWeb},
      pipe_through: [[:browser, :api], :other],
      matches: [
        {:get, "/", OneController, :index, []},
        {:get, "/:id", OneController, :show, []},
        {:post, "/", OneController, :create, []},
        {:put, "/:id", OneController, :update, []},
        {:patch, "/:id", OneController, :update, []},
        {:delete, "/:id", OneController, :delete, []}
      ],
      resources: []
    }

    [_, scope2 | _] = TestWeb.Router.get_scopes()
    assert scope2 == expected
  end

  test "supports resources" do
    expected = %{
      scope: {"/", TestWeb},
      pipe_through: [:browser],
      matches: [],
      resources: [
        {"/account", AccountController, []},
        {"/user", UserController, [only: [:show], singleton: true]}
      ]
    }

    [_, _, scope3 | _] = TestWeb.Router.get_scopes()
    assert scope3 == expected
  end

  test "nested resources" do
    expected = %{
      scope: {"/top", TestWeb},
      pipe_through: [:other],
      matches: [],
      resources: [
        {"/", TopController, [only: [:index, :show]],
         [
           {"/nested", NestedController, [only: [:show]]},
           {"/three", ThreeController, [],
            [
              {"/four", FourController, []}
            ]}
         ]}
      ]
    }

    [_, _, _, scope4 | _] = TestWeb.Router.get_scopes()
    assert scope4 == expected
  end

  # scope path: "/api/v1", as: :api_v1, alias: API.V1 do
  #   get "/pages/:id", PageController, :show
  # end
  test "scope with options only" do
    expected = %{
      scope: [path: "/api/v1", as: :api_v1, alias: API.V1],
      pipe_through: [],
      matches: [{:get, "/pages/:id", PageController, :show, []}],
      resources: []
    }

    [_, _, _, _, scope5 | _] = TestWeb.Router.get_scopes()
    assert scope5 == expected
  end

  # scope "/api/v1", API.V1, as: :api_v1 do
  #   get "/pages/:id", PageController, :show
  # end
  test "scope path alias options" do
    expected = %{
      scope: [alias: API.V1, path: "/api/v1", as: :api_v1],
      pipe_through: [],
      matches: [{:get, "/pages/:id", PageController, :show, []}],
      resources: []
    }

    [_, _, _, _, _, scope6 | _] = TestWeb.Router.get_scopes()
    assert scope6 == expected
  end
end
