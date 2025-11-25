# Bobot, a tool not suitable for lazy people

With Bobot YOU are the smart one, YOU are the one who thinks, YOU are the one who solves problems,
and YOU are the one who creates solutions. No dude, with Bobot there is not AIs, prompts,  visual 
interfaces designed for people who cannot type because their nail polish chips easily or faggy 
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

## The static part of a bot

A bot has a couple of part that can be considered static: **settings** and **hooks**. 

The **settings** are conformed by many keys, some of them mandatories. One of the main setting is 
`type`; it is mandatory and define what kind of bot you are creating (Ex: `[type: :telegram]`). 
Depending of the type of bot, will be necessary to complete other settings (Ex: for type :telegram 
you need to set `token`).

The **hooks** defile 3 important blocks: 
- `start_block`: it is the block that will be called when the user start communication with the bot. 
  For the `start_block` also will be necesary define how many parameters will receive; for that it 
  is used `start_params_count`. 
- `stop_block`: this hook define the block that will be called when the session end. 
- `fallback_block`: this hook define the block that will be called when the bot has any kind of 
  problem. 

## The basic blocks of a bot

A bot is made up of one or more of the 3 basic blocks defined in Bobot: 

- **block**: A **block** is one of the basic unit to build bots. It is defined with `defblock` 
    sentency and inside you must define the secuence of actions. The **blocks** are structures 
    callables that can be invoked from initial hooks (see below), fron another **block**, or from a 
    **command** (see below). 

- **command**: It is another basic unit. Some bots engine (example Telegram) allow define special
    message that are **commands**. These **commands** can interrupt the normal flow of the bot and 
    trigger some specific action. To define a **command** block it is used `defcommand`. 

- **channel**: A **channel** is a special block that define a kind of group of news for subscribers. 
    The user of the bot can send with a special command a subs or unsubs to the **channel** defined.
    Inside a channel you can define periodic task that will run every period and will send the 
    result of the task to the subscribers. A channel is defined with `defchannel` sentency.


# DSL Base specs

## Static definitions 

This sentencies are used just one time per bot. 

### defbot
Syntax:

```Elixir 
defbot <name>,  [
  type: <atom_type>,
  use_apis: <list_of_atoms>,
  use_libs: <list_of_atoms>,
  config: [ # this config is specific for each type of bot, example below is for type :telegram 
    token: <string>,
    session_ttl: <integer_miliseconds>,
    max_bot_concurrency: <integer>,
    expire_message: <string>
  ]
] do 
  # Here the code of the bot. See below for sentencies availables
  ...
  ...
end
```

### hooks
`hooks` sentency will be defined inside `defbot _ do ... end` block.  

Syntax:

```Elixir 
  hooks [
    start_block: <atom_block_name>,
    start_params_count: <integer>,
    stop_block: <atom_block_name>,
    fallback_block: <atom_block_name>
  ]
```

## Generic sentencies for bots

### defblock
Syntax:

```Elixir 
# without parameters (hook start_params_count: 0)
defblock <atom_name> do 
  ...
end

# with parameters 
defblock <atom_name>, receive: <params> do 
  ...
end
```

Notes:
- `<params>`: can be `<varname>` or [`<varname1>`, `<varname2>`, ...]


### defcommand
Syntax:

```Elixir 
defcommand <pattern> do 
  ...
end
```

Notes:
- `<pattern>`: an Elixir pattern (ex: `"/help " <> topic`, this example will match commands that
  start with "/help " and will store in the variable `topic` everything that follows).


### defchannel
Syntax:

```Elixir 
defchannel <atom_name> do 
  ...
end
```

### call_block
Syntax:

```Elixir 
# without parameters
call_block <atom_name> 

# with parameters 
call_block <atom_name>, params: <params> 
```

Notes:
- `<params>`: `<varname>` or [`<varname1>`, `<varname2>`, ...]


### call_api
See `defapi` in **APIs** for more details. 

Syntax:

```Elixir 
# The APIs ids are defined inside an API with `defcall` sentency. Se APIs for more details.

# without parameters
call_api <atom_id> 

# with parameters 
call_api <atom_id>, params: <params> 
```

Notes:
- `<params>`: `<varname>` or [`<varname1>`, `<varname2>`, ...]

### call_http
Syntax:

```Elixir 
call_http <string_url>, <opts> 
```

Notes:
- `<opts>`: a list with all or just some of this parameters
  ```elixir
  [
    method: :get,         # atoms :get or :post
    auth: :none,          # atoms :none or :basic 
    username: "<string>", # if auth: :basic
    password: "<string>", # if auth: :basic
    return_json: true,    # if true decode the body response as json and return a map
                          # if false return the raw body
    post_data: %{}        # a map with the post parameters 
  ]
  ```

### session_data
Return a map with all the datas accumulated during the session. 

Syntax:

```Elixir 
session_data() # pay attention at parenthesis, they are mandatory

# You could use it also in this way
session_data()[:firstname] # :firstname is an example
```

### session_data
Return a map with all the datas accumulated during the session. 

Syntax:

```Elixir 
session_data() # pay attention at parenthesis, they are mandatory

# You could use it also in this way
session_data()[:firstname] # :firstname is an example
```

### session_value
Recover a value from the session. Also allow in the same sentency recover and compare the value to
return a boolean value (see examples before)

Syntax:

```Elixir 
session_value <atom_key>[, <expr>]

# Examples
## get the value
session_value :firstname 
## or if you want store it in a variable
firstname = session_value :firstname 

## compare the value (guessing that session_value :firstname is "jimmy")
session_value :firstname, is: "jimmy"      # true
session_value :firstname, is_not: "jimmy"  # false
session_value :firstname, contains: "mm"   # true
session_value :firstname, icontains: "MM"  # true (ignore case)
session_value :firstname, match: ~r/^.i.+/ # true (regex for second letter is "i")
```

### session_store
Store one or more values in the session. 

Syntax:

```Elixir 
session_store <atom_key>, <value>
# Examples
session_store {:firstname, "jimmy"}
session_store firstname: "jimmy"
session_store firstname: "jimmy", lastname: "carter"
```


### every 
This sentency must be used inside a `defchannel _ do ... end` block. 

Syntax:

```Elixir 
every <pattern> do 
  ...
end
```

Notes:
- `<pattern>`: a special elixir pattern that must match erlang local_time. The erlang local_time
  function return `{{<year>, <month>, <day>}, {<hour>, <min>, <secs>}}`. A example pattern could 
  be: `{{_, _, _}, {_, 0, _}}`. This pattern will match every 1 hour exactly at 0 minutes (00:00, 
  01:00, 02:00, ... etc). 






