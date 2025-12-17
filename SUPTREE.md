## Processes:

- `Bobot.Utils.Assigns`: keep individual session values
- `Bobot.Utils.Storage`: store data about active sessions indexed by bot token.
- `Telegram.Poller`: it is a supervisor that launch 2 child by active bot, one for the poller and 
   the other the Genserver.
- `Bobot.Task`: write to `volatile_db` the channel tasks of every bot and run every minute the 
   tasks runner looking for task match. 

## What should I do if one of the process above crash?

- `Bobot.Utils.Assigns`: ... 

- `Bobot.Utils.Storage`: ... 

- `Telegram.Poller`: ... 

- `Bobot.Task`: ... 


                           MAIN SUP

                
