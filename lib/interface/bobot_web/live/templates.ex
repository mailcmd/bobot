defmodule BobotWeb.Templates do
  import Phoenix.Template, only: [embed_templates: 1]
  import BobotWeb.CoreComponents
  import BobotWeb.Components

  embed_templates "templates/*.html"

end
