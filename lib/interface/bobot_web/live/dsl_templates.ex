defmodule BobotWeb.DSLTemplates do
  import Phoenix.Template, only: [embed_templates: 1]
  import BobotWeb.Components

  embed_templates "../../../../lib/service/dsl/*/templates/*.html"

end
