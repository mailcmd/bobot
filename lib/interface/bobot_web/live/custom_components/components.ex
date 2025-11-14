defmodule BobotWeb.Components do
  use Phoenix.Component

  import BobotWeb.CoreComponents
  # alias Phoenix.LiveView.JS
  use Gettext, backend: BobotWeb.Gettext

  attr :type, :string, default: "button"
  attr :icon, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def small_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "small-button text-white bg-purple-800 hover:bg-purple-800 focus:outline-none focus:ring-4 focus:ring-purple-300",
        "dark:bg-purple-600 dark:hover:bg-purple-700 dark:focus:ring-purple-900",
        "font-medium rounded text-xs p-1.5 text-center items-center disabled:text-gray-400",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
      <%= if @icon != nil do %>
      <.icon name={"hero-#{@icon}"} class="ml-1 h-4 w-4" />
      <% end %>
    </button>
    """
  end

  attr :type, :string, default: "button"
  attr :value, :string, default: ""
  attr :icon, :string, default: nil
  attr :"icon-size", :string, default: "4"
  attr :class, :string, default: nil
  attr :rest, :global

  def icon_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={@class}
      value={@value}
      {@rest}
    >
      <.icon name={"hero-#{@icon}"} class={"h-#{assigns[:"icon-size"]} w-#{assigns[:"icon-size"]}"} />
    </button>
    """
  end

  attr :name, :string, default: nil
  attr :type, :string, default: "text"
  attr :label, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :value, :string, default: ""
  attr :inline, :boolean, default: false
  attr :rest, :global, include: ~w(required pattern)

  def input(assigns) do
    ~H"""
    <div class={[@inline && "inline-grid" || "grid", "mb-5 grid grid-cols-3"]}>
      <label for={@name} class="block text-xs px-2 py-3 align-middle text-right font-medium text-gray-900 dark:text-white"><%= @label %></label>
      <input type={@type} id={@name} name={@name} value={@value} placeholder={@placeholder} {@rest}  autocomplete="off" class="col-span-2 block bg-gray-50 border border-gray-300 text-gray-900 text-xs rounded-lg focus:ring-purple-500 focus:border-purple-500 p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-purple-500 dark:focus:border-purple-500"/>
    </div>
    """
  end

  attr :name, :string, default: nil
  attr :value, :string, default: ""

  def input_hidden(assigns) do
    ~H"""
    <input type="hidden" id={@name} name={@name} value={@value}/>
    """
  end

  attr :name, :string, default: nil
  attr :label, :string, default: ""
  attr :class, :string, default: nil
  attr :options, :list, default: []
  attr :emptyoption, :boolean, default: true
  attr :inline, :boolean, default: false
  attr :small, :boolean, default: false
  attr :value, :string, default: ""
  attr :rest, :global, include: ~w(required)

  def select(assigns) do
    ~H"""
    <div class={[@inline && "inline-grid" || "grid", "grid-cols-3 place-items-stretch"]}>
      <label for={@name}
        class={[
          "block text-xs px-2 py-3 align-middle text-right font-medium",
        ]}><%= @label %></label>
      <select id={@name} name={@name}
        class={[
          "block w-full p-2.5 col-span-2 bg-gray-50 border border-gray-300 text-gray-900 text-xs rounded-lg",
          "focus:ring-purple-500 focus:border-purple-500 place-self-center dark:bg-gray-700 dark:border-gray-600",
          "dark:placeholder-gray-400 dark:text-white dark:focus:ring-purple-500 dark:focus:border-purple-500",
          @small && "!h-8 !p-1",
          @class
        ]}
      >
        <option :if={@emptyoption}></option>
        <%= for {value, text} <- @options |> Enum.map(fn
              {val, text} -> {val, text}
              val -> {val, val}
            end) do %>
          <option value={value} selected={@value == value}><%= text %></option>
        <% end %>
      </select>
    </div>
    """
  end


end
