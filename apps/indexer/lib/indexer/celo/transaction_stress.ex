defmodule Indexer.Celo.TransactionStress do
  @moduledoc "Inserts and updates a large amount of transactions to stress test db"

  alias Explorer.Chain
  alias Explorer.Chain.{Block, Hash, Transaction}
  alias Explorer.Repo
  import Ecto.Query

  require Logger

  use GenServer

  @max_blocks 10000000
  @max_tx_per_block 1000

  @impl true
  def init(_) do
    state = %{
      block_numbers: MapSet.new([]),
      block_numbers_to_tx_count: %{},
      concurrency: 1
    }

    unless Application.fetch_env!(:indexer, :env) == "dev" do
      raise "Transaction stress test process is attached to supervision tree - this should only be run during development"
    end

    {:ok, state, {:continue, :clean_up}}
  end


  @spec start_link(term()) :: GenServer.on_start()
  def start_link(params \\ %{}) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def handle_continue(:clean_up, state) do
    from(b in Block, where: b.number < 0 ) |> Repo.delete_all()
    from(t in Transaction, where: t.block_number < 0 ) |> Repo.delete_all()

    max_legit_block_number = from(b in Block, select: max(b.number)) |> Repo.one()

    {:noreply, Map.put(state, :max_legit_block, max_legit_block_number)}
  end


  def generate_transaction(block_hash, block_number, index) do
    {:ok, transaction_hash} = Hash.Full.cast(block_number * 100000 + index)

    %{
      block_hash: block_hash,
      block_number: block_number,
      cumulative_gas_used: Enum.random(0..300000),
      from_address_hash: "0x0000000000000000000000000000000000000000",
      error: nil,
      input: "0xE026C4AF000000000000000000000000153E1F0FC7C2C8404A6E511D1C4D0734AED90F31",
      r: 0,
      s: 0,
      v: 0,
      value: 0,
      nonce: 46,
      gas_used: Enum.random(0..300000),
      gas: Enum.random(0..300000),
      gas_price: Enum.random(0..300000),
      hash: transaction_hash |> to_string(),
      index: index,
      status: nil
    }
  end

  def generate_block(number) do
    Logger.info("Generate block number #{number}")
    {:ok, hash} = number * 100000 |> Hash.Full.cast()

    %{
      consensus: true,
      number: number,
      hash: hash |> to_string(),
      parent_hash: hash |> to_string(),
      nonce: 46,
      to_address: "0x0000000000000000000000000000000000000000",
      from_address: "0x0000000000000000000000000000000000000000",
      miner_hash: "0x0000000000000000000000000000000000000000",
      data: "0xD983010503846765746889676F312E31362E3134856C696E7578000000000000F8CCC0C080B84112BB4B3A85D9A122974D4BAB016D3014CBB8796C77A247225DB3E35B1C88D80F2AFA96B0770AB8D80B4C2D6822B2FA106E6B18787FB8077401A3F065A83F075001F8418E27DBE7FFDB357E31A95CFE77CE79B08FDF2C22A47D328F4A29DC1F6C9816BF141FFC40206799FB38E1DB8A2079750E0A5C83AF8A4A7F5263A01DF38CAF060180F8418E3FFFFFFFFDBFFFFFFFFFFFFFFFFFB021562F7E38B2893A71E9181F10805B26D01EA13676818D81C31AA1232E14CCAA79C5A738D3E9D98987C2D10B4CDB5A8180",
      difficulty: Enum.random(1..100_000),
      total_difficulty: Enum.random(1..100_000),
      size: Enum.random(1..100_000),
      gas_limit: Enum.random(1..100_000),
      gas_used: Enum.random(1..100_000),
      timestamp: DateTime.utc_now(),
      refetch_needed: false
    }
  end

  @impl true
  def handle_cast({:insert, tx_count}, state) do
    state = insert_new_batch(state, tx_count)

    {:noreply, state}
  end

  def insert_new_batch(state = %{block_numbers: block_numbers, block_numbers_to_tx_count: ntx, max_legit_block: mbn}, tx_count \\ nil) do

    next_block_number = mbn + 10
    block = %{number: bn, hash: bh} = generate_block(next_block_number)

    tx_count = tx_count || Enum.random(0..@max_tx_per_block)

    transactions = (0..tx_count)
                   |> Enum.map(fn i ->
      generate_transaction(bh, bn, i)
    end)

    {:ok, _changes} = Chain.import(%{
      blocks: %{params: [block]},
      transactions: %{params: transactions},
    })

    %{ state | block_numbers: MapSet.put(block_numbers, bn), block_numbers_to_tx_count: Map.put(ntx, bn, length(transactions)) }
  end

  def get_new_block_number(block_numbers) do
    number = Enum.random(0..10000000)

    if MapSet.member?(block_numbers, number) do
      get_new_block_number(block_numbers)
    else
      number
    end
  end

end