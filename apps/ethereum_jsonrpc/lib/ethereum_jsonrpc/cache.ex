defmodule EthereumJSONRPC.Cache do
  use Nebulex.Cache,
    otp_app: :ethereum_jsonrpc,
    adapter: Nebulex.Adapters.Local
end
