import Config

config :ethereum_jsonrpc, EthereumJSONRPC.RequestCoordinator,
  rolling_window_opts: [
    window_count: 12,
    duration: :timer.seconds(30),
    table: EthereumJSONRPC.RequestCoordinator.TimeoutCounter
  ],
  wait_per_timeout: :timer.seconds(20),
  max_jitter: :timer.seconds(2)

# Add this configuration to add global RPC request throttling.
# throttle_rate_limit: 250,
# throttle_rolling_window_opts: [
#   window_count: 4,
#   duration: :timer.seconds(15),
#   table: EthereumJSONRPC.RequestCoordinator.ThrottleCounter
# ]

config :ethereum_jsonrpc, EthereumJSONRPC.Tracer,
  service: :ethereum_jsonrpc,
  adapter: SpandexDatadog.Adapter,
  trace_key: :blockscout

config :logger_json, :ethereum_jsonrpc,
  metadata:
    ~w(application fetcher request_id first_block_number last_block_number missing_block_range_count missing_block_count
       block_number step count error_count shrunk import_id transaction_id)a,
  metadata_filter: [application: :ethereum_jsonrpc]

config :logger, :ethereum_jsonrpc, backends: [LoggerJSON]

config :ethereum_jsonrpc, EthereumJSONRPC.Cache,
       # GC interval for pushing new generation: 12 hrs
       gc_interval: :timer.hours(12),
         # Max 1 million entries in cache
       max_size: 1_000_000,
         # Max 2 GB of memory
       allocated_memory: 2_000_000_000,
         # GC min timeout: 10 sec
       gc_cleanup_min_timeout: :timer.seconds(10),
         # GC max timeout: 10 min
       gc_cleanup_max_timeout: :timer.minutes(10)


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
