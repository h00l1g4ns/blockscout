defmodule EthereumJSONRPC.Cache do
  require Logger
  use Nebulex.Cache,
    otp_app: :ethereum_jsonrpc,
    adapter: Nebulex.Adapters.Local

  # don't cache call for "latest" block
  def cached_request(%{method: "eth_getBlockByNumber", params: ["latest", _]}), do: false
  def cached_request(%{method: "eth_getBlockByNumber", params: [block_number, include_tx?]}) do
    lookup({"eth_getBlockByNumber", block_number, include_tx?})
  end
  # don't cache anything else
  def cached_request(_), do: false

  @block_by_number_ttl :timer.minutes(5)
  def store_response(response, %{method: "eth_getBlockByNumber", params: [block_number, include_tx?]}) do
    Logger.info("Store #{block_number}")
    put({"eth_getBlockByNumber", response, include_tx?}, ttl: @block_by_number_ttl)
    response
  end
  def store_response(response, _request_params), do: response

  defp lookup(key) do
    case get(key) do
      nil -> nil
      response ->
        {:ok, response}
    end
  end
end
