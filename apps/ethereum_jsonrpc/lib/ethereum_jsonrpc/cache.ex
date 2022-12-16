defmodule EthereumJSONRPC.Cache do
  require Logger
  use Nebulex.Cache,
    otp_app: :ethereum_jsonrpc,
    adapter: Nebulex.Adapters.Local

  # don't cache call for "latest" block
  def cached_request(%{method: "eth_getBlockByNumber", params: ["latest", _]}), do: false
  # cache call for block number with full tx content
  def cached_request(%{method: "eth_getBlockByNumber", params: [block_number, true]}), do: lookup({"eth_getBlockByNumber", block_number})
  # don't cache anything else
  def cached_request(_), do: false

  @block_by_number_ttl :timer.minutes(5)
  def store_response(response, %{method: "eth_getBlockByNumber", params: [block_number, true]}) do
    Logger.info("Store #{block_number}")
    put({"eth_getBlockByNumber", response}, ttl: @block_by_number_ttl)
    response
  end
  def store_response(response, _request_params), do: response

  defp lookup(key) do
    case get(key) do
      nil -> nil
      response ->
        Logger.info("Cache hit ")

        {:ok, response}
    end
  end
end
