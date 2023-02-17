module SplittableRandoms

using Base: rand
using Random: Random, AbstractRNG, RandomDevice, rng_native_52, SamplerUnion

export SplittableRandom, split

###############################################################################
# constructors
###############################################################################

const GOLDEN_GAMMA = 0x9e3779b97f4a7c15

mutable struct SplittableRandom <: AbstractRNG
    seed::UInt64
    gamma::UInt64
end
SplittableRandom(seed::UInt64) = SplittableRandom(seed, GOLDEN_GAMMA)
function SplittableRandom(seed::Integer) # seed with integer. strategy taken from: https://github.com/JuliaRandom/RandomNumbers.jl/blob/20992caa581473dc805f9236760c35d96fbc4f29/src/Xorshifts/splitmix64.jl#L34
    sr = SplittableRandom(seed % UInt64) # initialize an SR by bitcasting the integer to UInt64
    sr.seed = rand(sr, UInt64)           # mix the seed and return
    return sr
end
function SplittableRandom()
    s = rand(RandomDevice(), UInt64)     # gen a seed using OS-provided entropy
    SplittableRandom(s)                  # no need to mix64 since RD produces good randomness. similar to https://github.com/JuliaLang/julia/blob/bd8dbc388c7b89f68838ca554ed7ba91740cce75/stdlib/Random/src/Xoshiro.jl#L143
end

# split an SR to create a new, uncorrelated SR 
function split(sr::SplittableRandom)
    SplittableRandom( rand(sr, UInt64), mix_gamma(next_seed!(sr)) )
end

###############################################################################
# sampling methods
###############################################################################

next_seed!(sr::SplittableRandom) = return sr.seed += sr.gamma

function mix_gamma(z::UInt64)
    z = xor(z, (z >> 33)) * 0xff51afd7ed558ccd
    z = xor(z, (z >> 33)) * 0xc4ceb9fe1a85ec53
    z = xor(z, (z >> 33)) | 1
    n = count_ones(xor(z, (z >> 1)))
    return (n < 24) ? xor(z, 0xaaaaaaaaaaaaaaaa) : z
end

function mix64(z::UInt64)
    z = xor(z, z >> 30) * 0xbf58476d1ce4e5b9
    z = xor(z, z >> 27) * 0x94d049bb133111eb
    xor(z, z >> 31)
end
Base.rand(sr::SplittableRandom, ::Type{UInt64}) = mix64(next_seed!(sr))

# SplittableRandom generates UInt64 natively
Random.rng_native_52(::SplittableRandom) = UInt64
# Example: trace of calls for randexp
# [1] randexp(rng::SplittableRandom)
# [2] rand(rng::SplittableRandom, X::Random.UInt52Raw{UInt64})
#   @ Random ~/opt/julia/usr/share/julia/stdlib/v1.7/Random/src/Random.jl:254 
# [3] rand(r::SplittableRandom, #unused#::Random.SamplerTrivial{Random.UInt52Raw{UInt64}, UInt64})
#   @ Random ~/opt/julia/usr/share/julia/stdlib/v1.7/Random/src/generation.jl:114
# [4] rng_native_52(::SplittableRandom) 
#   @ here

# RNG for several bit types
# Uses this approach: https://github.com/JuliaLang/julia/blob/793eaa3147239feeccf14a57dfb099411ed3bafe/stdlib/Random/src/Xoshiro.jl#L167
# but with the lower instead of the upper bits
@inline function Base.rand(
    rng::SplittableRandom,
    T::Random.SamplerUnion(Bool, Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64)
    )
    rand(rng, UInt64) % T[]
end

end # module
