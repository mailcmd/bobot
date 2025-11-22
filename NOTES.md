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

## NEW Feature for Telegram:

defchannel :<channel_name> do
  every <pattern> do
    ...
  end
end

'defchannel' action:
  - Define 'defcommand "/chsub <channel_name>" 
    Add to DETS {{:subs, <channel_name>}, <chat_id>}
  - Define 'defcommand "/chunsub <channel_name>" 
    Remove from DETS {{:subs, <channel_name>}, <chat_id>}

'every' action:
  - Create a uniq function with block do...end of every (<every_function>)
  - Add to ETS (every_db) {{:task, <pattern>}, <channel_name>, <every_function>}

We need a background process running that every minute read every_db rows, for each task 
check time with <pattern> and if it is a match run <every_function> and send the result to
the <channel_name>. 
