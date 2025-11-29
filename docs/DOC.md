# Bobot, a tool not suitable for lazy people

With Bobot YOU are the smart one, YOU are the one who thinks, YOU are the one who solves problems,
and YOU are the one who creates solutions. Yes dude!... with Bobot there is not AIs, no prompts, 
no visual interfaces designed for people who cannot type because their nail polish chips or faggy 
stuff like that, here YOU are the one who has to work. With Bobot YOU must type the instructions 
that says to the bot what to do. 

But it's not all that hard with Bobot because, through simple and fairly self-explanatory language, 
you can instruct complex behavior without getting bogged down in the details of how it should be 
done.

## A simple language for doing complex things

Bobot is made in Elixir programing language and define a DSL (Domain Specific Language) to program 
bots creating an abstraction layer that allow to do a lot with a little. Like the DSL is made in 
Elixir it is also dependant of its syntax rules. So, although you does not need to be an Elixir 
expert, it is important to know al least a little about the fundamentals of Elixir language. 

# Bobot DSL Reference

## Overview

- The DSL is implemented as compile-time macros in `Bobot.DSL.Base` and `Bobot.DSL.Telegram` (for now).
- `Bobot.DSL.Base` exposes general bot-building macros: `defbot`, `hooks`, `defblock`, `defcommand`, `defchannel`, session helpers (`session_data`, `session_value`, `session_store`), API/HTTP helpers (`call_api`, `call_http`), periodic tasks (`every`), and API/lib definition macros (`defapi` and `deflib`).
- `Bobot.DSL.Telegram` is a Telegram-specific layer that sets up module attributes (`@token`, `@session_ttl`, etc.), provides Telegram targeted message macros (`send_message`, `send_image`, `send_menu`, `edit_message`, `pin`/`unpin`, `terminate`), some native commands (`/chsub`, `/chunsub`, etc) and some behavior callbacks (`launch`, `stop`, `inform_to_subscribers`).
- The DSL follows Elixir language syntax rules.

**NOTE**: in the future will be created `Bobot.DSL.Whatsapp`, `Bobot.DSL.Discord` and others modules that implements the same bot-building macros as `Bobot.DSL.Telegram`. 

## Key module attributes created by Telegram DSL

- `@token` — bot token (set by passing config when using the DSL)
- `@session_ttl` — session time-to-live (defaults from app config)
- `@max_bot_concurrency` — optional max concurrency
- `@bots_dir`, `@apis_dir`, `@libs_dir` — compile-time app config
- `@bot_channels` — collects channel definitions declared via `defchannel`.

## Core macros (DSL Base)

#### `defbot <atom_name> [, opts] do ... end`

- Signature: `defbot :my_bot, type: <atom>, config: [...], use_apis: [...], use_libs: [...]`
- Internally creates a module `Bobot.Bot.<CamelizedName>` that uses `Bobot.Bot` behavior with given options and injects the block as the module body.
- Required `opts: :type` (e.g. `:telegram`)

Example:

```elixir
defbot :hello,  [
  type: :telegram,
  use_apis: [],
  use_libs: [ :common_lib ],
  config: [ # this config is specific for each type of bot, example below is for type :telegram 
    token: "BOT_TOKEN",
    session_ttl: 300_000,
    max_bot_concurrency: 1000,
    expire_message: "Bye bye!"
]
] do 
  # Here the code of the bot. 
end

```

#### `hooks [start_block: <atom>, start_params_count: <n>, ...]`

- Defines define 3 important block names.
- Options:
  - `:start_block` — the atom name of the initial run block (a defblock name)
  - `:start_params_count` — number of params to accept for the `:start_block`
  - `:stop_block` — atom name of block to run at end
  - `:fallback_block` — atom name of block run on exception

Example:

```elixir
hooks [
  start_block: :main, 
  start_params_count: 1, 
  stop_block: :cleanup, 
  fallback_block: :on_error
]
```

#### `defblock <atom_name) [, receive: <params>] do ... end`

- This is one of the basic unit to build bots. 
- `<params>` can be `<varname>` or [`<varname1>`, `<varname2>`, ...]

Example:

```elixir
defblock :main, receive: phone_number do
  send_message "Hello!"
end
```

#### `defcommand <string_pattern> do ... end`

- It is another basic unit. Some bots engines (example Telegram) allow define special
    message that are **commands**. These **commands** can interrupt the normal flow of the bot and 
    trigger some specific action.
- `<string_pattern>` - an Elixir pattern (ex: `"/help " <> topic`, this example will match commands that
  start with `"/help "` and will store in the variable `topic` everything that follows).

Example:

```elixir
defcommand "/say_hello " <> name do
  send_message "hello #{name}!"
end
```

#### `defchannel <channel_atom_name> [, description: <string>] do ... end`

- Define a channel and internally registers `{<channel_atom_name>, <description>}` in `@bot_channels` attribute
- Useful for setting up scheduled task
- Allow throuhg API call send messages to subscribers from an external source

Example:

```elixir
defchannel :daily, description: "Daily updates" do
  # send a message every day at 7am
  every {{_, _, _},{7, 0, _}} do
    send_message "Good morning!"
  end  
end
```

#### `call_block <atom_name>[, params: <params>]`

- Move the execution flow of the bot to block <atom_name>
- `<params>` - can be `<varname>` or [`<varname1>`, `<varname2>`, ...]

#### `break [returning: value]`

- Break out of flow with an optional returning value

#### `session_data()`

- Return a map with all the datas accumulated during the session. 

Example: 

```Elixir 
session_data() # pay attention at parenthesis, they are mandatory

# You also could use it in this way
session_data()[:firstname] # :firstname is an example
```

#### `session_value(<key>[, <expr>])`

- Recover a value from the session. Also allow in the same sentency recover and compare the value to return a boolean value (see examples below)
- <key> - can be <atom_key> or [<atom_key1>, <atom_key2>, ...] for recover a deep value in the map

Examples:
```Elixir 
## You can use 'session_value' with or without parentheses

## get the value
session_value :firstname 
## or if you want to store the value in a variable
firstname = session_value :firstname 

## compare the value (guessing that session_value(:firstname) is "jimmy")
session_value :firstname, is: "jimmy"      # true
session_value :firstname, is_not: "jimmy"  # false
session_value :firstname, contains: "mm"   # true
session_value :firstname, icontains: "MM"  # true (ignore case)
session_value :firstname, match: ~r/^.i.+/ # true (regex for second letter is "i")
```

#### `session_store(<list_of_key_value>)`
or 
#### `session_store(<atom_keys>, <value>)`

- Store one or more values in the session. 
- `<list_of_key_value>` - can be an elixir keyword list or a map (ex: `[firstname: "jimmy", lastname: "carter"]`) 
- `<atom_keys>` - is a list of atoms and allow deep store in the session map

```Elixir 
# Examples
## store a value
session_store firstname: "jimmy"
## store many values
session_store firstname: "jimmy", lastname: "carter"
## deep store
session_store [:user, :firstname], "jimmy"
```

### Using APIs and HTTP helpers

#### `call_api <atom_api_id>[, params: <params>]`

- Lookups in settings `:use_apis` list and tries find in order `<atom_api_id>` call in every API. The first match is called. The result is stored in the session under the key `<atom_api_id>`.
- See `defapi...` in **Defining APIs** for more details

```elixir
call_api :find_user, params: id
```

#### `call_http <string_url>, <opts>`

- Make a http call to the url with the options and return a map or a raw body
- can store the result in the session via `:store_in` option
- `<opts>` - can be a list with all or some of this parameters
  ```elixir
  [
    method: :get,         # atoms :get or :post
    auth: :none,          # atoms :none or :basic 
    username: "<string>", # if auth: :basic
    password: "<string>", # if auth: :basic
    return_json: true,    # if true decode the body response as json and return a map, if false return the raw body
                          # if false return the raw body
    post_data: %{}        # a map with the post parameters 
    store_in: <session_atom_key>
  ]
  ```

## Defining APIs

- defapi name do ... end
  - Creates a module Bobot.API.CamelName using Bobot.API for API call implementations.
- defcall name, do: block
  - Implement call(name, nil) inside the defapi module.
- defcall name, vars, do: block
  - Implement call(name, vars)



- call_http(url, opts \ [])
  - Macro to call http_request(url, opts) and store result in session via :store_in option.

Periodic tasks

- every(pattern, opts \ [], do: block)
  - Registers a task via Bobot.Task.add_task(__MODULE__, channel_name, pattern, func)
  - pattern is used to match the scheduling criteria; you can pass when: guard to add a guard expression.

Macros for libraries

- deflib name, do: block
  - Defines Bobot.Lib.CamelName module for shared helpers.

Macros for flow control

- await_response(opts)
  - Waits for next message and stores it in a variable.
  - Options:
    - :store_in — (required) variable name to store response into (passed as AST)
    - :extract_re — Regex to extract parts from incoming message; if provided it does Regex.scan and picks capture groups (hd |> tl)
    - :cast_as — optional type or list of types to cast using Bobot.Parser.parse; supports multiple cast types mapping to received values.
  - Behavior:
    - Sets token data for chat processes to {self(), engine} and flushes mailbox before receiving
    - Receives:
      - :stop -> kills process
      - :cancel -> returns :cancel
      - message (binary): returns message or extracted captures
    - Applies casts if cast options provided. If cast is list and multiple captures, maps accordingly.
  - There's also await_response(opts, do: block) which runs the block if response is not :cancel/:stop; if :cancel does :ok, if :stop calls terminate().

- call_http / call_api previously covered.

Compatibility macros
- send(message: message)
- send(message: message, menu: menu)
  - These forward to send_message or send_menu for backwards compatibility.

Core macros (Telegram-specific) from Bobot.DSL.Telegram

Note: Bobot.DSL.Telegram implements __using__(opts) — it expects opts to contain a :config keyword with :token (required). When a bot module uses this DSL (via Bobot.Bot perhaps), the following are set and imported.

Automatic / built-in commands
- defcommand "/chsub " <> channel — subscribe current chat to a channel (uses Bobot.Utils.channel_subscribe)
- defcommand "/chunsub " <> channel — unsubscribe

Callbacks implemented
- inform_to_subscribers(channel, subscribers, message)
  - Sends message to each subscriber using Telegram.Api methods: sendMessage, sendPhoto depending on map form message.
  - Supported message forms:
    - binary string -> sendMessage with HTML parse_mode.
    - %{type: :text, text: text}
    - %{type: :image, filename: filename} -> reads file and sendPhoto with file_content if exists
    - %{type: :image, url: url} -> sendPhoto with the URL

- launch()
  - Compiles the bot file, init_channels(), starts Telegram.Poller supervisor children for engine and poller tasks, etc.

- stop()
  - Terminates children in Telegram.Poller matching the token.

Messaging macros (Telegram-specific)

- send_message(message)
  - Sends a text message using Telegram.Api.request(@token, "sendMessage", [... chat_id, text, parse_mode: "HTML"]) 
  - Stores message id into session under :last_message_id.

- send_image(url_filename, opts \ [])
  - Two variants:
    - If argument starts with "http", treats as URL. If opts[:download] is true it downloads content (via Bobot.DSL.Base.http_request) and sends as {:file_content, content, filename}; otherwise sends URL directly.
    - If argument is filename (local), reads file and sends file_content.
  - Stores message id to :last_message_id.

- send_menu(menu, opts \ [])
  - menu expected as list; constructs inline_keyboard with callback_data as indices, encodes with Jason, sends as sendMessage with reply_markup and parse_mode HTML. Stores message id to :last_message_id.
  - opts: :message text to send with menu (default "")

- edit_message(opts \ [])
  - Edits message text using editMessageText; opts: message (text), message_id; if message_id is nil it uses last_message_id from session. Also supports :menu option to set an inline keyboard (reply_markup).

- pin_message(opts \ [])
  - Pins message using pinChatMessage, message_id defaults to last_message_id.

- unpin_message(opts \ [])
  - Unpin using pinChatMessage as well (note: implementation calls pinChatMessage; follow code as-is).

- terminate()
  - Tries to stop engine, unset session assigns and exits process. Also available terminate(message: message) which first sends message then terminates.

Other Telegram helper macros
- set_token_data / get_token_data / settings_remove — wrappers around Bobot.Utils.Storage.* with @token bound.

Utilities
- flush() — empties mailbox with receive loop until 10 ms timeout.

Macro import behavior
- The Telegram DSL imports itself and Kernel except send/2 (so DSL defines send macro variants for compatibility).

How to use sess_id and assigns
- Many macros expect var!(sess_id) to refer to the session identifier variable in the runtime context (session process id or session key).
- run_command signatures are run_command(cmd, sess_id_var, assigns)
- When using await_response, send_message, send_image, the macros read/writes assigns and session via Bobot.Utils.Assigns helpers and Bobot.Utils.Storage for token storage.

Examples

1) Minimal Telegram echo bot

```elixir
defbot :echo, type: :telegram, config: [token: "MY_BOT_TOKEN"] do
  hooks start_block: :main, fallback_block: :on_error

  defblock :main do
    # Wait a message and echo it back
    await_response store_in: msg
    case msg do
      :cancel -> send_message "Cancelled."
      :stop -> terminate()
      text when is_binary(text) ->
        send_message "You said: #{text}"
        # loop
        call_block :main
    end
  end

  defblock :on_error do
    send_message "Sorry, something went wrong."
  end
end
```

2) Command + menu example with an API call (pseudo)

```elixir
defbot :food, type: :telegram, config: [token: "TOKEN"], use_apis: [:food_api] do
  hooks start_block: :welcome, fallback_block: :on_err

  defblock :welcome do
    send_message "Welcome to FoodBot! Send /menu to see options."
  end

  defcommand "/menu" do
    # present menu buttons (inline)
    send_menu(["Pizza", "Sushi", "Tacos"], message: "Choose one:")
  end

  # react to callback presses in a block named :select - here assumed run is invoked by callback handler
  defblock :select, receive: {:choice, [], nil} do
    # hypothetical param 'choice' containing "1" index from send_menu callback_data
    # call API to get details
    call_api :food_details, params: [id: session_value(:user_id)]
    send_message "You chose something. I'll fetch details..."
  end

  defblock :on_err do
    send_message "Ops. Something bad happened."
  end
end
```

3) Using await_response with extraction and casting

```elixir
defcommand "/set_age" do
  send_message "Please enter your age (just the number):"
  await_response store_in: age_str, extract_re: ~r/(\d+)/, cast_as: :int
  case age_str do
    :cancel -> send_message "Operation cancelled."
    :stop -> terminate()
    age when is_integer(age) ->
      session_store age: age
      send_message "Saved your age: #{age}"
  end
end
```

4) Defining an API module used by call_api

```elixir
defapi :weather do
  defcall :get_current, do:
    # return map or value expected by call_api
    %{temp: 24, cond: "sunny"}
end
```

5) Using defchannel to create and init a channel

```elixir
defchannel :daily, description: "Daily news" do
  # for example schedule a daily task or register a background worker
  :ok
end
```

Notes and implementation details observed

- The DSL uses Bobot.Utils.Assigns for session-level storage and Bobot.Utils.Storage for token-level storage.
- http_request uses Tesla + Jason; when return_json: true it expects a JSON body and decodes to atoms keys.
- try_apis turns API names into module atoms like Elixir.Bobot.API.CamelName and calls call/2; if a module isn't found/rescuable it keeps trying the next API name.
- send_menu builds inline_keyboard where callback_data are indices starting at 1 (using :lists.enumerate then mapping).
- The Telegram DSL automatically defines default /chsub and /chunsub commands to manage channel subscriptions through Bobot.Utils.channel_subscribe/unsubscribe.
- last_message_id is updated after send_message/send_image/send_menu and is used by edit_message/pin/unpin when a message_id is not provided.

Suggested next steps when authoring bots

- Choose defbot name and ensure type: :telegram and config includes token: "..."
- Use hooks start_block to define the entry point block name
- Use defcommand to match literal commands or pattern matching commands (these are matched by incoming message text)
- Use defblock for receive-driven logic; call other blocks with call_block
- Use await_response to get the next user message in interactive flows
- Store persistent bot configuration in token storage with set_token_data/get_token_data
- Use call_api/call_http to fetch external data and store results into session for later use
