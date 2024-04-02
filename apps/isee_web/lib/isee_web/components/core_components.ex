defmodule IseeWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import IseeWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  slot(:inner_block, required: true)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-800/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-600/10 ring-zinc-600/10 relative hidden rounded-2xl bg-zinc-800 p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, default: "flash", doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="disconnected"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show("#disconnected")}
      phx-connected={hide("#disconnected")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a search box
  """
  attr(:class, :string, default: nil)
  attr(:results, :list, default: [])
  attr(:show_results, :boolean, default: false)
  attr(:query, :string, default: "")

  def search(assigns) do
    ~H"""
    <div class={["relative", @class]}>
      <form
        class="flex items-center w-full h-12 rounded border border-zinc-600 bg-zinc-800 p-2 pointer-events-auto"
        novalidate=""
        role="search"
        phx-change="search"
      >
        <input
          class="w-full my-1 mx-2 bg-transparent outline-none text-white"
          name="value"
          aria-autocomplete="both"
          phx-debounce="500"
          phx-focus="show-results"
          aria-controls="searchbox__results_list"
          autocomplete="off"
          autocorrect="off"
          autocapitalize="off"
          spellcheck="false"
          placeholder="Find something..."
          value={@query}
          tabindex="0"
        />
        <div class="w-px h-full bg-zinc-600 py-2 mx-3" />
        <button :if={@query != ""} type="button" class="mr-1" phx-click="clear">
          <.icon name="hero-x-mark" class="w-6 h-6 bg-white" />
        </button>
        <button :if={@query == ""} type="button">
          <.icon name="hero-magnifying-glass" class="w-6 h-6 bg-white" />
        </button>
      </form>
      <div
        :if={@show_results}
        class="flex-shrink overflow-y-scroll bg-zinc-800 rounded border border-t-2 border-zinc-600 -mt-1 pointer-events-auto"
        id="searchbox__results_list"
      >
        <ul class="list-none divide-y divide-zinc-600" phx-click-away="hide-results">
          <li
            :for={res <- @results}
            class="py-2 px-4 text-white hover:bg-zinc-700 cursor-pointer flex space-x-2 items-center"
            phx-click={JS.push("search-result", value: res)}
          >
            <img :if={not is_nil(res.icon_url)} src={res.icon_url} class="invert w-6 h-6" />
            <span><%= res.text %></span>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form}} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr(:for, :any, required: true, doc: "the datastructure for the form")
  attr(:as, :any, default: nil, doc: "the server side parameter to collect all input under")

  attr(:rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  slot(:inner_block, required: true)
  slot(:actions, doc: "the slot for form actions, such as a submit button")

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-zinc-800">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr(:type, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:secondary, :boolean, default: false)
  attr(:rest, :global, include: ~w(disabled form name value))

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg py-2 px-3 text-sm font-semibold leading-6 text-white active:text-white/80",
        (if @secondary, do: "bg-zinc-600 hover:bg-zinc-700", else: "bg-indigo-500 hover:bg-indigo-400"),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr(:id, :any, default: nil)
  attr(:name, :any)
  attr(:label, :string, default: nil)
  attr(:value, :any)

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)
  )

  attr(:field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"
  )

  attr(:errors, :list, default: [])
  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")

  attr(:rest, :global,
    include: ~w(autocomplete cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step)
  )

  slot(:inner_block)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-1 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-white placeholder-zinc-400 shadow-sm sm:text-sm sm:leading-6 bg-white/[0.05]",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          "min-h-[6rem] border-zinc-300 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-md px-3 py-2 placeholder-zinc-400 shadow-sm text-white sm:leading-6 bg-white/[0.05]",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          "border-zinc-300 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr(:for, :string, default: nil)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-white">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr(:class, :string, default: nil)
  attr(:breadcrumbs, :list, default: [])

  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <div>
      <div :if={not Enum.empty?(@breadcrumbs)}>
        <nav class="sm:hidden" aria-label="Back">
          <.link navigate={List.last(@breadcrumbs) |> elem(1)} class="flex items-center text-sm font-medium text-zinc-400 hover:text-zinc-200">
            <.icon name="hero-chevron-left-mini" class="-ml-1 h-5 w-5 flex-shrink-0 text-zinc-500" />
            Back
          </.link>
        </nav>
        <nav class="hidden sm:flex" aria-label="Breadcrumb">
          <ol role="list" class="flex items-center space-x-4">
            <li :for={{{name, path}, idx} <- Enum.with_index(@breadcrumbs)}>
              <div class="flex items-center">
                <.icon :if={idx > 0} name="hero-chevron-right-mini" class="h-5 w-5 mr-4 flex-shrink-0 text-zinc-500" />
                <.link navigate={path} class="text-sm font-medium text-zinc-400 hover:text-zinc-200"><%= name %></.link>
              </div>
            </li>
            <li>
              <div class="flex items-center text-sm font-medium text-zinc-400">
                <.icon name="hero-chevron-right-mini" class="h-5 w-5 mr-4 flex-shrink-0 text-zinc-500" />
                <%= render_slot(@inner_block) %>
              </div>
            </li>
          </ol>
        </nav>
      </div>
      <div class="mt-2 md:flex md:items-start md:justify-between">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight"><%= render_slot(@inner_block) %></h2>
          <p :if={@subtitle != []} class="text-sm leading-6 text-zinc-200">
            <%= render_slot(@subtitle) %>
          </p>
        </div>
        <div class="mt-4 flex flex-shrink-0 space-x-3 md:mt-0 md:ml-4">
          <%= for action <- @actions do %> 
            <%= render_slot(action) %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-white font-medium">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-600 border-t border-zinc-700 text-sm leading-6 text-zinc-50"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-600">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-600 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-50"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-600 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-50 hover:text-zinc-200"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a form filter
  """
  attr :meta, Flop.Meta, required: true
  attr :fields, :list, required: true
  attr :id, :string, default: nil
  attr :on_change, :string, default: "update-filter"
  attr :target, :string, default: nil

  def filter_form(%{meta: meta} = assigns) do
    assigns = assign(assigns, form: Phoenix.Component.to_form(meta), meta: nil)

    ~H"""
    <.form
      for={@form}
      id={@id}
      phx-target={@target}
      phx-change={@on_change}
      phx-submit={@on_change}
    >
      <Flop.Phoenix.filter_fields :let={i} form={@form} fields={@fields}>
        <.input
          field={i.field}
          label={i.label}
          type={i.type}
          phx-debounce={120}
          {i.rest}
        />
      </Flop.Phoenix.filter_fields>

      <button class="button" name="reset">reset</button>
    </.form>
    """
  end

  @doc ~S"""
  Renders a table with pagination.

  ## Examples

      <.page_table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.page_table>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:meta, :map, required: true)
  attr(:path, :any, required: true)
  attr(:filter_fields, :list, default: [])
  attr(:rest, :global)
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def page_table(%{meta: meta, path: path} = assigns) do
    assigns =
      assigns
      |> assign(
        :page_link_helper,
        Flop.Phoenix.Pagination.build_page_link_helper(meta, path)
      )
    
    ~H"""
    <.filter_form
      :if={not Enum.empty?(@filter_fields)}
      fields={@filter_fields}
      meta={@meta}
      id={"#{@id}-filter"} />
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <Flop.Phoenix.table
        items={@rows}
        meta={@meta}
        path={@path}
        row_click={@row_click}
        row_item={@row_item}
        opts={[
          table_attrs: [class: "w-[40rem] mt-11 sm:w-full"],
          thead_attrs: [class: "text-sm text-left leading-6 text-white"],
          thead_th_attrs: [class: "p-0 pr-6 pb-4 font-semibold"],
          tbody_attrs: [
            class:
              "relative divide-y divide-zinc-700 border-t border-zinc-600 text-sm leading-6 text-zinc-50"
          ],
          tbody_tr_attrs: [class: "group hover:bg-zinc-800"],
          tbody_td_attrs: [class: "relative p-0 hover:cursor-pointer"]
        ]}
        {@rest}
      >
        <:col
          :for={{col, i} <- Enum.with_index(@col)}
          :let={row}
          attrs={[class: "relative p-0 hover:cursor-pointer"]}
          {col}
        >
          <div class="block py-4 pr-6">
            <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-800 sm:rounded-l-xl" />
            <span class={["relative", i == 0 && "font-semibold text-zinc-300"]}>
              <%= render_slot(col, row) %>
            </span>
          </div>
        </:col> 
        <:action :let={row} attrs={[class: "relative w-14 p-0"]}>
          <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
            <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-800 sm:rounded-r-xl" />
            <span
              :for={action <- @action} 
              class="relative ml-4 font-semibold leading-6 text-zinc-100 hover:text-zinc-200"
            >
              <%= render_slot(action, row) %>
            </span>
          </div>
        </:action>
      </Flop.Phoenix.table>
      <p :if={Enum.count(@rows) == 0} class="text-sm text-white italic text-center py-4">There are no results.</p>
    </div>
    <div class="flex items-center justify-between border-t border-zinc-400 px-4 py-3 sm:px-6">
      <div class="flex flex-1 justify-between sm:hidden">
          <.pagination_link
            disabled={!@meta.has_previous_page?}
            disabled_class="text-zinc-400 select-none hover:bg-zinc-900 active:text-zinc-400"
            page={@meta.previous_page}
            path={@page_link_helper.(@meta.previous_page)}
            class="relative inline-flex items-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700 leading-6 active:text-white/80"
          >
            Previous
          </.pagination_link>
          <.pagination_link
            disabled={!@meta.has_next_page?}
            disabled_class="text-zinc-700 select-none hover:border-zinc-500 hover:text-zinc-500"
            page={@meta.next_page}
            path={@page_link_helper.(@meta.next_page)}
            class="relative inline-flex items-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700 leading-6 active:text-white/80"
          >
            Next
          </.pagination_link>
      </div>
      <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-zinc-200">
            Showing
            <select
              name="limit"
              class="mt-1 inline-block rounded-md border border-zinc-700 bg-zinc-800 shadow-sm shadow-zinc-900 focus:border-zinc-700 focus:ring-0 sm:text-sm"
            >
              <option :for={val <- [10, 20, 50, 75, 100]} value={val} selected={val == @meta.page_size} phx-click={JS.navigate(Flop.Phoenix.Pagination.build_page_link_helper(Map.update!(@meta, :flop, &Map.put(&1, :page_size, val)), @path).(1))}><%= val %></option>
            </select>
            of
            <span class="font-medium"><%= @meta.total_count %></span>
            results
          </p>
        </div>
        <div>
          <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
            <.pagination_link
              disabled={!@meta.has_previous_page?}
              disabled_class="!text-zinc-400 select-none hover:bg-zinc-800"
              page={@meta.previous_page}
              path={@page_link_helper.(@meta.previous_page)}
              class="relative inline-flex items-center rounded-l-md border border-zinc-700 bg-zinc-800 px-2 py-2 text-sm font-medium text-zinc-200 hover:bg-zinc-700 focus:z-20"
            >
              <span class="sr-only">Previous</span>
              <.icon name="hero-chevron-left-mini" class="h-5 w-5" />
            </.pagination_link>
            <.page_links
              meta={@meta}
              page_link_helper={@page_link_helper}
            />
            <.pagination_link
              disabled={!@meta.has_next_page?}
              disabled_class="!text-zinc-400 select-none hover:bg-zinc-800"
              page={@meta.next_page}
              path={@page_link_helper.(@meta.next_page)}
              class="relative inline-flex items-center rounded-r-md border border-zinc-700 bg-zinc-800 px-2 py-2 text-sm font-medium text-zinc-200 hover:bg-zinc-700 focus:z-20"
            >
              <span class="sr-only">Next</span>
              <.icon name="hero-chevron-right-mini" class="h-5 w-5" />
            </.pagination_link>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  attr :meta, Flop.Meta, required: true
  attr :page_link_helper, :any, required: true

  defp page_links(%{meta: meta} = assigns) do
    max_pages =
      Flop.Phoenix.Pagination.max_pages({:ellipsis, 3}, assigns.meta.total_pages)

    range =
      first..last =
      Flop.Phoenix.Pagination.get_page_link_range(
        meta.current_page,
        max_pages,
        meta.total_pages
      )

    assigns = assign(assigns, first: first, last: last, range: range)

    ~H"""
    <.pagination_link
      :if={@first > 1}
      page={1}
      path={@page_link_helper.(1)}
      {attrs_for_link(1, @meta)}
    >
      1
    </.pagination_link>

    <span :if={@first > 2} class="relative inline-flex items-center border border-zinc-700 bg-zinc-800 px-4 py-2 text-sm font-medium text-zinc-200">...</span>

    <.pagination_link
      :for={page <- @range}
      page={page}
      path={@page_link_helper.(page)}
      {attrs_for_link(page, @meta)}
    >
      <%= page %>
    </.pagination_link>

    <span :if={@last < @meta.total_pages - 1} class="relative inline-flex items-center border border-zinc-700 bg-zinc-800 px-4 py-2 text-sm font-medium text-zinc-200">...</span>

    <.pagination_link
      :if={@last < @meta.total_pages}
      page={@meta.total_pages}
      path={@page_link_helper.(@meta.total_pages)}
      {attrs_for_link(@meta.total_pages, @meta)}
    >
      <%= @meta.total_pages %>
    </.pagination_link>
    """
  end

  defp attrs_for_link(page, %{current_page: page}), 
    do: [class: "relative z-10 inline-flex items-center border border-indigo-500 bg-indigo-900/50 px-4 py-2 text-sm font-medium text-white focus:z-20", aria: [current: "page"]]

  defp attrs_for_link(page, _), 
    do: [class: "relative inline-flex items-center border border-zinc-700 bg-zinc-800 px-4 py-2 text-sm font-medium text-zinc-200 hover:bg-zinc-700 focus:z-20"]

  attr :path, :string
  attr :on_paginate, JS, default: nil
  attr :event, :string
  attr :target, :string
  attr :page, :integer, required: true
  attr :disabled, :boolean, default: false
  attr :disabled_class, :string
  attr :rest, :global
  slot :inner_block

  defp pagination_link(
         %{disabled: true, disabled_class: disabled_class} = assigns
       ) do
    rest =
      Map.update(assigns.rest, :class, disabled_class, fn class ->
        [class, disabled_class]
      end)

    assigns = assign(assigns, :rest, rest)

    ~H"""
    <span {@rest} class={@disabled_class}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  defp pagination_link(%{event: event} = assigns) when is_binary(event) do
    ~H"""
    <.link phx-click={@event} phx-target={@target} phx-value-page={@page} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp pagination_link(%{on_paginate: nil, path: path} = assigns)
       when is_binary(path) do
    ~H"""
    <.link patch={@path} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp pagination_link(%{} = assigns) do
    ~H"""
    <.link
      patch={@path}
      phx-click={@on_paginate}
      phx-target={@target}
      phx-value-page={@page}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Renders a loading line
  """
  attr(:loading, :boolean, required: true)

  slot(:inner_block, required: true)

  def loading(assigns) do
    ~H"""
    <%= if @loading do %>
      <div class="animate-pulse inline-block align-middle w-full max-w-xs h-2 bg-slate-200 rounded">
      </div>
    <% else %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  attr(:title, :string, default: nil)

  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <h2 :if={@title} class="text-md font-semibold leading-8 mb-4"><%= @title %></h2>
      <dl class="-my-4 divide-y divide-zinc-700">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-white"><%= item.title %></dt>
          <dd class="w-full text-zinc-400"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr(:navigate, :any, required: true)
  slot(:inner_block, required: true)

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-white hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid an mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr(:name, :string, required: true)
  attr(:class, :string, default: nil)

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(IseeWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(IseeWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
