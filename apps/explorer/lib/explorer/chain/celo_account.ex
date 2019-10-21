
defmodule Explorer.Chain.CeloAccount do
    @moduledoc """

    """
  
    require Logger
  
    use Explorer.Schema
  
    alias Explorer.Chain.{Hash, Wei, Address}
  
#    @type account_type :: %__MODULE__{ :regular | :validator | :group }

    @typedoc """
    * `address` - address of the account.
    * `account_type` - regular, validator or validator group
    * `gold` - cGLD balance
    * `usd` - cUSD balance
    * `locked_gold` - voting weight
    * `notice_period` - 
    * `rewards` - rewards in cGLD
    """

    @type t :: %__MODULE__{
        address: Hash.Address.t(),
        account_type: String.t(),
        gold: Wei.t(),
        usd: Wei.t(),
        locked_gold: Wei.t(),
        notice_period: integer,
        rewards: Wei.t()
    }

    @attrs ~w(
        address account_type gold usd locked_gold notice_period rewards
    )a

    @required_attrs ~w(
        address
    )a

    # Validator events
    @validator_registered_event "0x4e35530e670c639b101af7074b9abce98a1bb1ebff1f7e21c83fc0a553775074"
    def validator_registered_event, do: @validator_registered_event

#    @validator_group_member_added "0xbdf7e616a6943f81e07a7984c9d4c00197dc2f481486ce4ffa6af52a113974ad"
#    @validator_group_member_removed "0xc7666a52a66ff601ff7c0d4d6efddc9ac20a34792f6aa003d1804c9d4d5baa57"

    @validator_group_registered "0x939d2ce9990e1bdc223c6f065c5f11b09b9c1ab8d78d224711c2823e0e3d6af7"
    @validator_group_deregistered "0xae7e034b0748a10a219b46074b20977a9170bf4027b156c797093773619a8669"

    @validator_affiliated "0x91ef92227057e201e406c3451698dd780fe7672ad74328591c88d281af31581d"
    @validator_deaffiliated "0x71815121f0622b31a3e7270eb28acb9fd10825ff418c9a18591f617bb8a31a6c"

    # Locked gold events
    @account_created "0x805996f252884581e2f74cf3d2b03564d5ec26ccc90850ae12653dc1b72d1fa2"

    @gold_withdrawn "0x292d39ba701489b7f640c83806d3eeabe0a32c9f0a61b49e95612ebad42211cd"
    @gold_unlocked "0xb1a3aef2a332070da206ad1868a5e327f5aa5144e00e9a7b40717c153158a588"
    @gold_locked "0x0f0f2fc5b4c987a49e1663ce2c2d65de12f3b701ff02b4d09461421e63e609e7"

#    @withdrawal "0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65"
#    @commitment_extended "0x0bc777c8576820f4a28d80a04ac50b4e07fd6923caa67f52059d5df938917b70"
#    @commitment_notified "0x8ee34f4f80d81bf361408efb771ad4cd664aefa5856aebfa85cfb772ad613193"
#    @new_commitment "0x178836574cee05ae88734424adca5b6039fa073e985267dc8a26ed466410a831"

    # Election events
    @validator_group_vote_revoked "0xa06c722f7d446349fdd811f3d539bc91c7b11df8a2f4e012685712a30068f668"
    @validator_group_vote_activated "0x50363f7a646042bcb294d6afdef2d53f4122379845e67627b6db367f31934f16"
    @validator_group_vote_cast "0xd3532f70444893db82221041edb4dc26c94593aeb364b0b14dfc77d5ee905152"

    # Events for updating account
    def account_events, do: [
        @gold_withdrawn,
        @gold_unlocked,
        @gold_locked, 
        @account_created,
        @validator_group_vote_revoked, 
        @validator_group_vote_activated,
        @validator_group_vote_cast
    ]

    # Events for updating validator
    def validator_events, do: [
        @validator_registered_event,
        @validator_affiliated,
        @validator_deaffiliated
    ]

    # Events for updating validator group
    def validator_group_events, do: [
        @validator_group_registered,
        @validator_group_deregistered
    ] 

    # Events for notifications
    def withdrawal_events, do: [
        @gold_withdrawn, 
        @gold_unlocked, 
        @gold_locked
    ]

    schema "celo_account" do
        field(:account_type, :string)
        field(:gold, Wei)
        field(:usd, Wei)
        field(:locked_gold, Wei)
        field(:notice_period, :integer)
        field(:rewards, Wei)

        belongs_to(
            :account_address,
            Address,
            foreign_key: :address,
            references: :hash,
            type: Hash.Address
        )

        timestamps(null: false, type: :utc_datetime_usec)
    end

    def changeset(%__MODULE__{} = celo_account, attrs) do
        celo_account
      |> cast(attrs, @attrs)
      |> validate_required(@required_attrs)
      |> unique_constraint(:address)
    end

end
