# The problem
  Need a way to store a bot that allow add/edit/delete.  

# Example model
```elixir

  block :start, receive: muid do
    call_api :authenticate, params: muid
    case session_value(:authentication) do
      :error ->
        terminate message: "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"
      _ ->
        send message: "Bienvenido, decime qué querés buscar..."
        call_block :loop
    end
  end

```

# IDEAS 

1- A kind of simplified AST: 

```elixir
[:block, [:start, receive: muid], []]
```
    |    \_____________________/   |
    |               |              |
    V               V              V
sentency          params        do block (empty if not applicable)
 (atom)        (quoted expr)    

How would example look?

```elixir

[:block, [:start, receive: muid], [
  [:call_api, [:authenticate, params: muid], []],
  [:case, [session_value(:authentication)], [
    [:error, [], [
      [:terminate, [message: "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"], []]
    ]],
    [_, [], [
      [:send, [message: "Bienvenido, decime qué querés buscar..."], []],
      [:call_block, [:loop], []]
    ]]
  ]]
]]  

defmodule T do
def quote_string(str) do
  Code.eval_string("""
  quote do
    #{str}
  end
  """) |> elem(0)
end
end

```

How to store a bot body?

```elixir
[:block, [:start, {:receive, {:muid, [], Elixir}}], [
  [:call_api, [:authenticate, {:params, {:muid, [], Elixir}}], []],
  [:case, [{:session_value, [], [:authentication]}], [

  ]]
]]
```

2- Lines leveled: 

```elixir
[0, :block, [:start, receive: muid]]
```
 |      |    \_____________________/
 |      |               |           
 V      V               V           
lbl  sentency          params        
      (atom)        (quoted expr)    

How would an example look?

```elixir
[0, :defblock, [:start, receive: muid]],
  [1, :call_api, [:authenticate, params: muid]],
  [1, :case, [session_value(:authentication)]],
    [2, :error, []],
      [3, :terminate, [message: "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"]],
    [2, :_, []],
      [3, :send, [message: "Bienvenido, decime qué querés buscar..."]],
      [3, :call_block, [:loop]],
[0, :defblock, [:stop, nil]],
  [1, :terminate, [message: "Chau master!"]]
```

{:__block__, [],
 [
   {:import, [line: 1], [{:__aliases__, [line: 1], [:Bobot, :DSL, :Base]}]},
   {:defbot, [line: 3],
    [
      :smi,
      _,
      _
    ]
   }
 ]
}

# NEW Feature for Telegram:

defchannel <channel_name> do
  every <pattern> do
    ...
  end
end

WE MUST DEFINE in telegram.ex (DSL)
- Define 'defcommand "/chsub <channel_name>" 
  Will add to static_db {{:subs, <channel_name>}, <chat_id>}
- Define 'defcommand "/chunsub <channel_name>" 
  Will remove from static_db {{:subs, <channel_name>}, <chat_id>}

'defchannel' action:
  - add to @bot_channels attr the <channel_name>
  - create the function 'init_channel(<channel_name>)' that run <block>

'every' action:
  - Add to ETS (volatile_db) {{:task, <pattern>}, <channel_name>, <every_function>}
  - Create a uniq function with block do...end of every (<every_function>)

When bobot start will check if every active bot has defined @bot_channels attribute. It it 
has, then will run 'init_channel(<channel_name>)'. 

Also bobot will start a background process that every minute read volatile_db and for each 
task that match the current time with <pattern> run <every_function> and send the result to
the subs of <channel_name>. 

The users of the bot can subscribe to <channel_name> using '/chsub <channel_name>'. 
Every 'defchannel' must acumulate in the @bot_channels attribute of the bot the <channel_name>. 

Messages to subscriber can come from 2 source: 
1. An 'every' task: the 'every' task will be linked to its 'defchannel' parent. When its
   pattern match, that will trigger the call of uniq function and send the result to the 
   subs of the channel. 
2. An API call: bobot app will have a REST API callable with a url that will 
   set channel and contain of the message. In this way will be possible to send message to
   channel subs from external source. 

~~IMPORTANT!!! When init the app we must create a process (genserver) that will subscribe to~~ 
~~every channel present in the @bot_channels attribute of every active bot.~~ 
~~When  dinamically we active a bot the genserver will must subscribe~~



