#Synthetix V3 Perps Market Fuzz Suite

##Run fuzz instantaneously

```
forge install perimetersec/fuzzlib@main --no-commit &&
forge install foundry-rs/forge-std --no-commit &&
mv lib markets/perps-market/lib &&
PATH=./contracts/fuzzing/:$PATH echidna contracts/fuzzing/Fuzz.sol --contract Fuzz --config echidna.yaml
```


###Installation

```
forge install perimetersec/fuzzlib@main --no-commit &&
forge install foundry-rs/forge-std --no-commit &&
mv lib markets/perps-market/lib

```

###Go to perps dir
`cd markets/perps-market`

###Run Foundry
`forge test --mt test_modifyCollateral`

###Run Echidna with no Slither check (fast)

```PATH=./contracts/fuzzing/:$PATH echidna contracts/fuzzing/Fuzz.sol --contract Fuzz --config echidna.yaml```

###Run Echidna with a Slither check (slow)

```echidna contracts/fuzzing/Fuzz.sol --contract Fuzz --config echidna.yaml```