# Bobot DSL Reference

Overview

- The DSL is implemented as compile-time macros in Bobot.DSL.Base and Bobot.DSL.Telegram.
- Bobot.DSL.Base exposes general bot-building macros: defbot, hooks, defblock, defcommand, defchannel, session helpers, API/HTTP helpers, periodic tasks, and API/lib definition macros.
- Bobot.DSL.Telegram is a Telegram-specific layer that sets up module attributes (@token, @session_ttl, etc.), provides Telegram targeted message macros (send_message, send_image, send_menu, edit_message, pin/unpin, terminate) and default Telegram callbacks (/chsub, /chunsub, launch, stop, inform_to_subscribers).
- The DSL follows Elixir syntax; these are macros you use inside bot module definitions.

Key module attributes created by Telegram DSL

- @token — bot token (set by passing config when using the DSL)
- @session_ttl — session time-to-live (defaults from app config)
- @max_bot_concurrency — optional max concurrency
- @bots_dir, @apis_dir, @libs_dir — compile-time app config
- @bot_channels — collects channel definitions declared via defchannel (persist: true, accumulate: true)

Core macros (from Bobot.DSL.Base)

1) defbot(name, opts \ [], do: block)

- Signature: defbot :my_bot, type: <atom>, config: [...], use_apis: [...], use_libs: [...]
- Creates a module Bobot.Bot.<CamelizedName> that uses Bobot.Bot with given options and injects the block as the module body.
- Required opts: :type (e.g. :telegram)

Example:

```elixir
defbot :hello, type: :telegram, config: [token: "BOT_TOKEN"] do
  # body: use hooks/blocks/commands below
end
```

2) hooks(opts \ [])

- Defines start_bot/3 which will run the start_block, optionally stop_block and uses fallback_block for errors.
- Options:
  - :start_block — the atom name of the initial run block (a defblock name)
  - :start_params_count — number of params to accept (generates param vars a, b, c...)
  - :stop_block — atom name of block to run at end
  - :fallback_block — atom name of block run on exception

Example:

```elixir
hooks start_block: :main, start_params_count: 1, stop_block: :cleanup, fallback_block: :on_error
```

3) defblock(name, opts \ [], do: block)

- Defines run(name, receive_vars, sess_id) implementation.
- opts: :receive — receive-pattern variables (default :_)
- This is the main building block where conversation steps and logic run.

Example:

```elixir
defblock :main, receive: {:_, [], nil} do
  send_message "Hello!"
end
```

4) defcommand(command, do: block)

- Defines run_command/3 for a literal command string (pattern match).
- When incoming message matches command pattern, the block runs.

Example:

```elixir
defcommand "/start" do
  send_message "Welcome!"
end
```

5) defchannel(channel_atom, opts \ [], do: block)

- Registers @bot_channels {channel_atom, description} and defines init_channel(channel_atom) that runs the block during init_channels().
- Useful for setting up scheduled or channel-specific initialization.

Example:

```elixir
defchannel :daily, description: "Daily updates" do
  # run initialization for :daily channel
  :ok
end
```

6) call_block(name, opts \ [])

- Runs run(name, params, sess_id) — handy to call other blocks.

7) break() / break(returning: value)

- Throws to break out of flow with optional value.

Session helpers and storage

- session_data() -> returns map of all session assigns: Bobot.Utils.Assigns.get_all(sess_id)
- session_value(key) -> Bobot.Utils.Assigns.get(sess_id, key)
- session_value(keys :: list) -> Bobot.Utils.Assigns.get_in(sess_id, keys)
- session_value(key, is: val) / is_not: / contains: / icontains: / match:
  - Comparison helpers returning boolean (useful in guards inside blocks)
- session_store(map_or_list) -> store multiple keys into session assigns
- session_store({keys, value}) -> nested put_in style store

Backward compatibility:
- value_of(key) mirrors session_value

Token-level settings (for token-specific persistent storage)
- set_token_data(key, value) — stores token-scoped data via Bobot.Utils.Storage.set_token_data(@token, key, value)
- set_token_data([{k, v}]) — convenience
- get_token_data(key) — retrieve token-level data
- settings_remove(key) — remove token-level setting

APIs and HTTP helpers

- defapi name do ... end
  - Creates a module Bobot.API.CamelName using Bobot.API for API call implementations.
- defcall name, do: block
  - Implement call(name, nil) inside the defapi module.
- defcall name, vars, do: block
  - Implement call(name, vars)

- call_api(id, opts \ [])
  - Lookups module attributes :bot_apis for this module and tries APIs in order via try_apis. Results are stored in session under id.
  - try_apis attempts to call Bobot.API.<CamelizedApi>.call(id, params) for each API name in the configured :bot_apis attributes.

- http_request(url, opts \ [])
  - Utility function (not macro) that uses Tesla to call external HTTP endpoints.
  - Default opts: method: :get, auth: :none, return_json: true, post_data: %{}
  - auth: :basic requires :username and :password in opts
  - return_json: true will attempt to decode JSON and return decoded map; otherwise raw Tesla response returned.

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
