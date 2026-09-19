# Basis

Rights and restrictions intelligence for tokenized real-world assets on Robinhood Chain.

Basis answers one question that block explorers do not: can this token actually
move right now, and if not, why not.

Status: early. The transfer probe is the only working component. Everything else
in the documentation is marked as planned or unverified.

## Quick start

    bash basis-probe.sh
    cd basis
    npm install
    npm test
    npm run probe -- --from 0xYourAddress --to 0xOtherAddress

Docs: see `docs/`.
