defmodule Explorer.Celo.Cache do
  require Logger
  use Nebulex.Cache,
      otp_app: :explorer,
      adapter: Nebulex.Adapters.Local
end
