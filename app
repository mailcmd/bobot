#!/bin/bash


export PHX_HOST=0.0.0.0
export PORT=4500

# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) #"
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")") #"
LOG_LEVEL=debug
LOG_FILE=/var/log/bobot.log

cd $SCRIPT_DIR

. config/local/env

case $1 in
    start)
      elixir --sname bobot -S mix phx.server --no-halt -- --log-file $LOG_FILE --log-level $LOG_LEVEL
      ;;

    init)
      elixir --sname bobot -S mix phx.server -- --log-level $LOG_LEVEL
      echo
      echo "VirtualOLT initilized. Now you can start the service with 'service virtualolt start'"
      echo
      ;;


    stop)
      (elixir --sname update --rpc-eval bobot "System.halt(0)" ; exit 0)
      ;;

    console)
      iex --remsh bobot --sname console
      ;;

    dev)
      iex -S mix phx.server --no-halt -- --log-file $LOG_FILE --log-level $LOG_LEVEL
      ;;

    restart)
      #elixir --sname update --rpc-eval spi_acs@localhost "Reload.doit()"
      ${BASH_SOURCE[0]} stop
      ${BASH_SOURCE[0]} start
      ;;

    log)
      tail -f $LOG_FILE
      ;;

    *)
      echo "Usage:"
      echo
      echo " ${BASH_SOURCE[0]} (start|stop|console|restart|log)"
      ;;
esac
