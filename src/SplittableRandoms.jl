module SplittableRandoms

using Base: rand
using Random: Random, AbstractRNG, RandomDevice, rng_native_52

export SplittableRandom, split

###############################################################################
# constructors
###############################################################################

const GOLDEN_GAMMA = UInt64(0x9e3779b97f4a7c15)

mutable struct SplittableRandom <: AbstractRNG
    seed::UInt64
    gamma::UInt64
end
SplittableRandom(seed::UInt64) = SplittableRandom(seed, GOLDEN_GAMMA)
function SplittableRandom()
    s = rand(RandomDevice(), UInt64) # similar to https://github.com/JuliaLang/julia/blob/bd8dbc388c7b89f68838ca554ed7ba91740cce75/stdlib/Random/src/Xoshiro.jl#L143
    g = mix_gamma(s+GOLDEN_GAMMA)
    SplittableRandom(s,g)
end

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

function mix64(sr::SplittableRandom, z::UInt64)
    s = sr.seed
    z = xor(s, s >> 30) * 0xbf58476d1ce4e5b9
    z = xor(z, z >> 27) * 0x94d049bb133111eb
    xor(z, z >> 31)
end
Base.rand(sr::SplittableRandom, ::Type{UInt64}) = mix64(sr, next_seed!(sr))

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

end # module
