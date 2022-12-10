# SplittableRandoms.jl

A minimal Julia translation of Java SplittableRandoms.

## Installation

In Julia, execute
```julia
]add SplittableRandoms
```

## Comparison to other Julian SplitMix64 implementations

The package [RandomNumbers](https://github.com/JuliaRandom/RandomNumbers.jl)
exposes a [SplitMix64](https://github.com/JuliaRandom/RandomNumbers.jl/blob/master/src/Xorshifts/splitmix64.jl)
implementation. However, it uses a fixed `gamma` value, and thus it cannot
currently support splitting.
