import Config

config :bobot, telegram_bots_defaults: [
  session_ttl: 60 * 1000
]

config :bobot, telegram_bots: [
  :smi
]
