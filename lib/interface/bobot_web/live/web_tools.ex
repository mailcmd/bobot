defmodule BobotWeb.WebTools do

  import Phoenix.LiveView
  import Phoenix.Component

  def include(template, assigns) do
    Phoenix.Template.render(BobotWeb.Templates, template, "html", assigns)
  end

  def put_message(socket, message, timeout \\ 3500)
  def put_message(socket, nil, _), do: socket
  def put_message(socket, message, timeout) do
    result_ok = socket.assigns[:last_result] == :ok
    socket
      |> push_event("js-exec", %{ js: """
        clearTimeout(window.flash_timeout)
      """ })
      |> clear_flash()
      |> put_flash(result_ok && :info || :error, message)
      |> push_event("js-exec", %{ js: """
        window.flash_timeout = setTimeout(()=>document.querySelectorAll('#flash-group > div').forEach(d=>d.style.display='none'), #{timeout})
      """ })
  end

  def clear_message(socket) do
    clear_flash(socket)
  end

  def open_modal(socket, map) do
    socket
      |> assign(modal: map)
      |> push_event("js-exec", %{ js: """
        modal.showModal();
      """ })
  end
  def close_modal(socket) do
    socket
      |> assign(modal: %{})
  end

end
