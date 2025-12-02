# Bobot DSL Reference

## Overview

- The DSL is implemented as compile-time macros in `Bobot.DSL.Base` and `Bobot.DSL.Telegram` (for now).
- `Bobot.DSL.Base` exposes general bot-building macros: `defbot`, `hooks`, `defblock`, `defcommand`, `defchannel`, session helpers (`session_data`, `session_value`, `session_store`), API/HTTP helpers (`call_api`, `call_http`), periodic tasks (`every`), and API/lib definition macros (`defapi` and `deflib`).
- `Bobot.DSL.Telegram` is a Telegram-specific layer that sets up module attributes (`@token`, `@session_ttl`, etc.), provides Telegram targeted message macros (`send_message`, `send_image`, `send_menu`, `edit_message`, `pin`/`unpin`, `terminate`), some native commands (`/chsub`, `/chunsub`, etc) and some behavior callbacks (`launch`, `stop`, `inform_to_subscribers`).
- The DSL follows Elixir language syntax rules.

**NOTE**: in the future will be created `Bobot.DSL.Whatsapp`, `Bobot.DSL.Discord` and others modules that implements the same bot-building macros as `Bobot.DSL.Telegram`. 

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
  # send a message every day at 7am (see 'every' below)
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

Examples:
```Elixir 
## store a value
session_store firstname: "jimmy"
## store many values
session_store firstname: "jimmy", lastname: "carter"
## deep store
session_store [:user, :firstname], "jimmy"
```

#### `every <pattern>[, when: <guard>] do ... end`
- This sentency must be used inside a `defchannel <...> do ... end` block. 
- `<pattern>` - must be a elixir pattern match erlang local_time. The erlang local_time
  function return `{{<year>, <month>, <day>}, {<hour>, <min>, <secs>}}`. An example pattern could 
  be: `{{_, _, _}, {_, 0, _}}`. This pattern will match every 1 hour exactly at 0 minutes (00:00, 
  01:00, 02:00, ... etc). 
- `<guard>` - must be a logic expression. You could set an every pattern like this `every {{_, _, _}, {_, min, _}}, when: (rem(min,2) == 0) do ... end` to match every even minute.


### Using APIs and HTTP helpers

#### `call_api <atom_api_id>[, params: <params>]`

- Lookups in settings `:use_apis` list and tries find in order `<atom_api_id>` call in every API. The first match is called. The result is stored in the session under the key `<atom_api_id>`.
- See `defapi...` in **Defining APIs** for more details

```elixir
call_api :find_user, params: id
```

#### `call_http <string_url>, <opts>`

- Make a http call to the url with the options and return a map or a raw body
- Can store the result in the session via `:store_in` option
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

# Engine specific macros (DSL implemented for Telegram for now)

This DSL is a standar and should implement complete or partially by any engine added to Bobot. So, 
the DSL stated below applies to Telegram and should also apply to other engines added in the future.

#### `send_message <string_message>`
- Sends a text message. For default accept html tags supported by the engine
- Stores message id into session under `:last_message_id`
- Return the `<message_id>`

#### `send_image <url_filename>[, download: true]`

This sentency has 2 variants:
- If argument starts with "http", treats as URL. If opts `:download` is true it downloads content and sends the file content, otherwise sends the URL directly.
- If argument is a local filename, reads file and sends the file_content.
- In both cases stores message id into session under `:last_message_id`
- Return the `<message_id>`


#### `send_menu <list_menu>[, message: <string>]`
- `<list_menu>` - must be as list; for telegram see docs about **inline_keyboard**
- optional :message text can be send with the menu (default none)
- Return the `<message_id>`

#### `edit_message message: <text>[, message_id: <message_id>]`
  - Edits a message identified by its id.
  - `<message_id>` - if `<message_id>` is not set, it uses `:last_message_id` from session. 

#### `pin_message [message_id: <message_id>]`
  - Pins a message
  - `<message_id>` - if `<message_id>` is not set, it uses `:last_message_id` from session. 

#### `unpin_message [message_id: <message_id>]`
  - unpins a message
  - `<message_id>` - if `<message_id>` is not set, it uses `:last_message_id` from session. 

#### `terminate([message: <message>])`
  - Terminate the chat session
  - `message: <message>` allow sends message before and then terminates

#### `await_response [cast_as: :integer|:string|:float, extract_re: <regex>, store_in: <session_key>]`
  - Freeze execution and wait for a message from the user.
  - The message is always text but can be casted as integer of float using `:cast_as`
  - Can store the result in the session via `:store_in` option
  - Return the message (casted if required)

## Mandatory implementations for each engine

### Channel support
Every engine, if it will support channels functionality, must define 2 commands:
- `defcommand "/chsub " <> channel` — to subscribe to a channel 
- `defcommand "/chunsub " <> channel` — to unsubscribe from a channel 

### Callbacks that must be implemented

#### `inform_to_subscribers(channel, subscribers, message)`
- Sends message to each subscriber.
- The message supported for now are:
  - Just text.
  - A map like this to send text: `%{type: :text, text: text}`
  - A map like this to send image: `%{type: :image, filename: filename}` 
  - A map like this to send image: `%{type: :image, url: url}`

#### `launch()`
- Compiles the bot file, init_channels() and init the necessary supervised processes.

#### `stop()`
- Terminate the supervised processes.


# Defining APIs

Bobot allow to define call APIs identified by one id. The API calls can be grouped in API modules to be availables for the any bot.

#### `defapi <atom_name> do ... end`
  - Creates a module for API call implementations

Example:
```elixir
defapi :quotes do 
  # For 'defcall' explanation see below 
  defcall :get_quote do 

    # 'http_request' function is part of the common lib available on APIs (see below)
    # This url return a json like this:
    # {
    #  "author": "Maurice Wilkes",
    #  "quote": "By June 1949 people had begun to realize that it 
    #     was not so easy to get programs right as at one time 
    #     appeared."
    # }
    http_request("https://programming-quotesapi.vercel.app/api/random")
  end
end

# And the bot could use it in this way
defbot :daily_quote, [type: :telegram, config: [...], use_apis: [:quotes]] do 
  defchannel :dayly_quote do 
    every {{_,_,_}, {7,0,_}} do 
      call_api :get_quote
      send_message session_value([:get_quote, :quote])
    end
  end
end
```

#### `defcall <atom_name>[, <params>] do ... block`
  - Implement an API call.
  - `<params>` - can be `<varname>` or `[<varname1>, <varname2>, ...]`
  - These API calls can be called with `call_api ...` (see above)

# Defining libraries

#### `deflib <atom_name> do ... block`
  - Defines lib module for shared helpers. 
  - Libs can be imported to a bot using the setting `:use_libs`.
  - The body of the lib is simply Elixir code. 



# Examples

## Minimal Telegram echo bot

```elixir
defbot :echo, type: :telegram, config: [token: "MY_BOT_TOKEN"] do
  hooks start_block: :main, fallback_block: :on_error

  defblock :main do
    # Wait a message and echo it back
    await_response store_in: msg
    send_message "You said: #{msg}"
    call_block :main
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
    send_menu ["Pizza", "Sushi", "Tacos"], message: "Choose one:"
    await_response store_in: food
    # The API call return %{data: <data_about_the_food_selected>}
    call_api :food_details, params: session_value(:food)
    send_message "You chose this: #{session_value([:food_detail, :data])}"
  end

  defblock :on_err do
    send_message "Ops. Something bad happened."
  end
end
```

