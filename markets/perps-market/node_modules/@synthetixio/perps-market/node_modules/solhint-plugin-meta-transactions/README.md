# solhint-plugin-meta-transactions

[Solhint](https://protofire.github.io/solhint/) plugin for ensuring implementation of erc2771 (Secure Protocol for Native Meta Transactions)

## Installation

Available on npm:

```sh
npm install solhint-plugin-meta-transactions --save-dev
```

## Usage

Enable the plugin in your project's `.solhint.json`:

```json
{
  "extends": "solhint:recommended",
  "plugins": ["meta-transactions"],
  "rules": {
    "meta-transactions/no-msg-sender": "error",
    "meta-transactions/no-msg-data": "error"
  }
}
```
