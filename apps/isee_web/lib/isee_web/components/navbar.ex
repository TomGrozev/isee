defmodule IseeWeb.Navbar do
  @moduledoc """
  Components of the Navbar
  """

  use IseeWeb, :live_component
  alias Phoenix.LiveView.JS

  def render(assigns) do
    links = [
      {:dashboard, ~p"/"},
      {:map, ~p"/map"},
      {:cameras, ~p"/cameras"}
    ]

    assigns = assign(assigns, :links, links)

    ~H"""
    <nav class="fixed w-full top-0 left-0 z-20 bg-zinc-900">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 justify-between">
          <div class="flex">
            <div class="-ml-2 mr-2 flex items-center md:hidden">
              <!-- Mobile menu button -->
              <button
                id="mobile-menu-btn"
                type="button"
                class="inline-flex items-center justify-center rounded-md p-2 text-zinc-600 hover:bg-zinc-800 hover:text-white focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                aria-controls="mobile-menu"
                aria-expanded="false"
                phx-click={toggle_menu()}
              >
                <span class="sr-only">Open main menu</span>
                <.icon name="hero-bars-3" class="block h-6 w-6" />
                <.icon name="hero-x-mar" class="hidden h-6 w-6" />
              </button>
            </div>
            <div class="flex flex-shrink-0 items-center">
              <.icon name="hero-eye" class="w-8 h-8 text-zinc-400" />
            </div>
            <div class="hidden md:ml-6 md:flex md:items-center md:space-x-4">
              <.link
                :for={{link, path} <- @links}
                navigate={path}
                class={["px-3 py-2 rounded-md text-sm font-medium", (if @active_tab == link, do: "bg-zinc-800 text-white", else: "text-zinc-300 hover:bg-zinc-700 hover:text-white")]}
              >
                <%= Phoenix.Naming.humanize(link) %>
              </.link>
            </div>
          </div>
          <div class="flex items-center">
            <div class="hidden md:ml-4 md:flex md:flex-shrink-0 md:items-center">
              <button
                type="button"
                class="rounded-full bg-zinc-800 p-1 text-zinc-400 hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-zinc-800"
              >
                <span class="sr-only">View notifications</span>
                <.icon name="hero-bell" class="w-6 h-6" />
              </button>
              <!-- Profile dropdown -->
              <div class="relative ml-3 group">
                <div>
                  <button
                    type="button"
                    class="flex rounded-full bg-zinc-800 text-sm focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-zinc-800"
                    id="user-menu-button"
                    aria-expanded="false"
                    aria-haspopup="true"
                  >
                    <span class="sr-only">Open user menu</span>
                    <img
                      class="h-8 w-8 rounded-full"
                      src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                      alt=""
                    />
                  </button>
                </div>
                <div
                  class="absolute right-0 z-50 mt-2 w-48 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none transition ease-in-out duration-200 transform scale-95 opacity-0 group-hover:scale-100 group-hover:opacity-100"
                  role="menu"
                  aria-orientation="vertical"
                  aria-labelledby="user-menu-button"
                  tabindex="-1"
                >
                  <a
                    href="#"
                    class="block px-4 py-2 text-sm text-zinc-700 hover:bg-zinc-50"
                    role="menuitem"
                    tabindex="-1"
                    id="user-menu-item-0"
                  >
                    Your Profile
                  </a>

                  <a
                    href="#"
                    class="block px-4 py-2 text-sm text-zinc-700 hover:bg-zinc-50"
                    role="menuitem"
                    tabindex="-1"
                    id="user-menu-item-1"
                  >
                    Settings
                  </a>

                  <a
                    href="#"
                    class="block px-4 py-2 text-sm text-red-700 hover:bg-zinc-50"
                    role="menuitem"
                    tabindex="-1"
                    id="user-menu-item-2"
                  >
                    Sign out
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Mobile menu, show/hide based on menu state. -->
      <div class="hidden" id="mobile-menu">
        <div class="space-y-1 px-2 pt-2 pb-3 sm:px-3">
          <.link
            :for={{link, path} <- @links}
            navigate={path}
            class={["block px-3 py-2 rounded-md text-base font-medium", (if @active_tab == link, do: "bg-zincj-900 text-white", else: "text-zinc-300 hover:bg-zinc-700 hover:text-white")]}
          >
            <%= Phoenix.Naming.humanize(link) %>
          </.link>
        </div>
        <div class="border-t border-zinc-700 pt-4 pb-3">
          <div class="flex items-center px-5 sm:px-6">
            <div class="flex-shrink-0">
              <img
                class="h-10 w-10 rounded-full"
                src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                alt=""
              />
            </div>
            <div class="ml-3">
              <div class="text-base font-medium text-white">Tom Cook</div>
              <div class="text-sm font-medium text-zinc-400">tom@example.com</div>
            </div>
            <button
              type="button"
              class="ml-auto flex-shrink-0 rounded-full bg-zinc-800 p-1 text-zinc-400 hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-zinc-800"
            >
              <span class="sr-only">View notifications</span>
              <.icon name="hero-bell" class="w-6 h-6" />
            </button>
          </div>
          <div class="mt-3 space-y-1 px-2 sm:px-3">
            <a
              href="#"
              class="block rounded-md px-3 py-2 text-base font-medium text-zinc-400 hover:bg-zinc-700 hover:text-white"
            >
              Your Profile
            </a>

            <a
              href="#"
              class="block rounded-md px-3 py-2 text-base font-medium text-zinc-400 hover:bg-zinc-700 hover:text-white"
            >
              Settings
            </a>

            <a
              href="#"
              class="block rounded-md px-3 py-2 text-base font-medium text-red-400 hover:bg-zinc-700 hover:text-red-600"
            >
              Sign out
            </a>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  defp toggle_menu(js \\ %JS{}) do
    js
    |> JS.toggle(
      to: "#mobile-menu",
      in:
        {"transition ease-out duration-200", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"},
      out:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.toggle(to: "#mobile-menu-btn .hero-*")
  end

  defp hide_menu(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#mobile-menu",
      trasition:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.hide(to: "#mobile-menu-btn .hero-*")
  end
end
