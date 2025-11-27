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
- [ ] Default commands: help, chsub, chunsub, chls
- [x] IMPORTANT: enhance how engine manage flow interrupt with commands (maybe a different session?)
- [ ] Base: add constants definitions (attributes)
- [ ] Duplicate BOT y API
- [x] Telegram: add send_image 
- [x] Interface web: add Telegram "command ..." as blocks
- [ ] Base: add task schedule that trigger actions every time period
- [ ] API to sent messages to channels
- [ ] See what can make with connections between blocks


```elixir
  # look for call_block's
  Bobot.Tools.ast_find(b[:loop][:block], :call_block) |> Enum.map( fn {_,_, [x]} -> x end) |> Enum.filter(&is_atom/1)
```

## Components
- Nodes are equal a BLOCKS. So the main unit of process is the "block". 
- Inside a block came the logic. The logic is a sequence of sentencies, including 
  conditional sentencies (probably case and cond, not if).
- From one block it is possible jump to another block. 
- Input can came from 2 sites: user input and API calls.
- The session keep track of many sessions variables and API call results values. 

## Base sentencies 
- bot_config: uniq and set the enviroment and behaviour of the bot. 
- block: declare a node and can define what receive.
- command: declare a command node.
- call_block: just that, jump to another block. 
- call_api: call to API (see API calls definitions)
- session_store: store a value referenced by a key in the session. 
- session_value: recover a session value by its key.

## Telegram sentencies
- await_response: just await for user message and can store the message sent in one o more
  variables. Even it is possible to parse the message and extract part of it to store as 
  some type of data (string, intenger, boolean, etc). 
- send_message: allow to send a text message.
- send_menu: allow to send a buttons menu.
- edit_message: just that, allow edit message content.
- pin_message: allow to pin a message.
- unping_message: well, obviuosly unpin messages.
- terminate: stop the bot session. 
- settings_set: store a setting.
- settings_get: recover a setting value by its key. 


## Structure to store code 

```elixir 
#Base

[:bot_config, 
  [
    start_block: block_name,
    start_params: params,
    stop_block: block_name,
    fallback_block: block_name
  ]
]

[:block, name, [receive: params], 
  [
    [...],
    [...]
  ]
] 

[:command, command_pattern, 
  [
    [...],
    [...]
  ]
] 

[:call_block, [params: params]]
[:call_api, call_id, [params: params]]
[:session_store, list_of_key_value]
[:session_store, {keys, values}]
[:session_value, list_keys]
[:session_value, key]

# Telegram 
[:await_response, opts]
[:send_message, text]
[:send_menu, list_menu]
[:edit_message, opts]
[:pin_message, [message_id: message_id]]
[:unping_message, [message_id: message_id]] 
[:terminate, [message: message]]
[:settings_set, {key, value}]
[:settings_get, key]


## Example bot SMI

[
  [:bot_config, [
    start_block: :start,
    start_params: phone,
    stop_block: :good_bye,
    fallback_block: :good_bye
  ]],
  [:block, :start, [receive: muid], [
    [:call_api, :authenticate, [params: muid]],
    [:case, session_value(:authentication), [
      [:error, [
        [:terminate, [message: "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"]]
      ]],
      [_, [
        [:send_message, "Bienvenido, decime qué querés buscar..."],
        [:call_block, :loop]
      ]]
    ]]
  ]]
]


```

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

