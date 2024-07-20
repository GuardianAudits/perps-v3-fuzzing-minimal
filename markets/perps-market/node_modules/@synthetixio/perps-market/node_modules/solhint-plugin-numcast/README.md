# solhint-plugin-numcast

[solhint](https://protofire.github.io/solhint/) plugin for detecting overflows in numeric (uint/int) casts. It helps avoiding low level numeric casts which can lead to silent overflows.

## Installation

Available on npm:

```sh
npm install solhint-plugin-numcast --save-dev
```

## Usage

Enable the plugin in your project's `.solhint.json`:

```json
{
  "extends": "solhint:recommended",
  "plugins": ["numcast"],
  "rules": {
    "numcast/safe-cast": "error"
  },
}
```
