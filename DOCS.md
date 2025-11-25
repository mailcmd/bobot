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

## The basic blocks of a bot

A bot is made up of one or more of the 3 basic blocks defined in Bobot: 

    - *block*: A *block* is one of the basic unit to build bots. It is defined with `defblock` 
      sentency and inside details a secuence of actions. The *blocks* are structures callables that 
      can be invoked from initial hooks, fron another *block*, or from a *command* (see below). 

    - *command*: It is another basic unit. Some bots engine (example Telegram) allow define special
      message that are *commands*. These *commands* can interrupt the normal flow of the bot and 
      trigger some specific action. For defining a *command* block it is used `defcommand`. 

    - *channel*: A *channel* is a special block that define a kind of group of news for subscribers. 
      The user of the bot can send with a special command a subs or unsubs to the *channel* defined.
      Inside a channel you can define periodic task that will run every period and will send the 
      result of the task to the subscribers. A channel is defined with `defchannel` sentency.

# DSL 

## Base 

### defblock
**Syntax**:



