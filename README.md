# Bobot

A tool where YOU are the smart one!! 
A tool where YOU are the one who thinks!!
A tool where YOU're still the smart one!!
A tool where YOU remain the smart one!!
A tool for those who prefer to keep using their brains!!
A tool where YOU are the one who solves problems!!
A tool where YOU are the one who creates solutions!!
A tool where YOU are the one who invent solutions!!
A tool where YOU are the one who build solutions!!


## TODO

- [x] Move render_table from telegram to tools
- [x] Make assigns variable more specific for every step
- [x] Base: call_http 
- [x] Make the Creator interface
    [x] defapi 
    [x] defcall 
- [x] IMPORTANT: enhance how engine manage flow interrupt with commands (maybe a different session?)
- [x] Base: add constants definitions (attributes)
- [x] Telegram: add send_image 
- [x] Interface web: add Telegram "command ..." as blocks
- [x] Base: add task schedule that trigger actions every time period
- [x] every with guards
- [x] Reload active BOT
- [ ] Default commands: help, chsub, chunsub, chls
- [ ] chsub, chunsub FEEDBACK
- [ ] Duplicate BOT y API
- [ ] API to sent messages to channels
- [ ] See what can make with connections between blocks


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bobot, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bot>.


defmodule MyModule do
  Module.put_attribute(__MODULE__, :custom_threshold_for_lib, 10)
  def a, do: @custom_threshold_for_lib
end
