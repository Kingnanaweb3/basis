# BASIS token

Status: proposed. No contract is deployed. Nothing on this page exists yet.

## Honest framing

A read only data product does not inherently need a token. There is one
defensible justification, and the design below rests entirely on it: the core
risk of this product is bad data, and a token can act as the bond that makes
published data costly to get wrong.

If that justification does not convince you, it should not convince anyone else
either. It is stated plainly rather than dressed up.

## Proposed design

**BASIS**, an ERC-20 on Robinhood Chain. It has no gas role, because gas on this
chain is paid in ETH.

**Attestation bonds.** Publishing or updating a claim profile requires posting a
BASIS bond. The entry goes live immediately.

**Challenge and slash.** A challenge window during which anyone can dispute an
entry by matching the bond. A wrong publisher loses their bond to the
challenger. A wrong challenger loses theirs to the publisher.

**Query fees.** High volume API consumers pay in BASIS. Fees route to bonded
attesters.

## Known weaknesses

Dispute resolution in a first version would be arbitrated by a project
controlled multisig. Real decentralised arbitration is a long project, not a
short one. This is a centralisation point and is named as such.

With no users, token price would be driven by liquidity and narrative rather
than fee flow. Any claim otherwise would be false.
