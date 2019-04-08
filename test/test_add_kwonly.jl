module TestAddKwonly
try
    using Test
catch
    using Base.Test
end
using Reconstructables: @add_kwonly, add_kwonly
import Reconstructables
include("utils.jl")

@add_kwonly function f(a, b; c=3, d=4)
  (a, b, c, d)
end
@test f(1, 2) == (1, 2, 3, 4)
@test f(a=1, b=2) == (1, 2, 3, 4)
@test_throws Reconstructables.UndefKeywordError f()

@add_kwonly g(a, b; c=3, d=4) = (a, b, c, d)
@test g(1, 2) == (1, 2, 3, 4)
@test g(a=1, b=2) == (1, 2, 3, 4)

@add_kwonly h(; c=3, d=4) = (c, d)
@test h() == (3, 4)

@add_kwonly with_type(a::A; b::B=2) where {A, B} = (a, A, b, B)
@test with_type(a=10, b=10.0) == (10, Int, 10.0, Float64)

@add_kwonly typed_kwonly(; a::A=1, b::B=2) where {A, B} = (a, A, b, B)
@test typed_kwonly(a=10, b=10.0) == (10, Int, 10.0, Float64)

@add_kwonly with_kwargs(a; b=2, kwargs...) =
    (a, b, Any[(k, v) for (k, v) in kwargs])
@test with_kwargs(a=10, x=20) == (10, 2, Any[(:x, 20)])

if VERSION >= v"0.7-"
    @eval @add_kwonly required_kwargs(a; b, c=3) = (a, b, c)
    @test required_kwargs(1, b=2) == (1, 2, 3)
    @test required_kwargs(a=1, b=2) == (1, 2, 3)
end


@test_error begin
    @eval @add_kwonly i(c=3, d=4) = (c, d)
end (err) -> begin
    @test err isa ErrorException
    @test contains(err.msg,
                   "At least one positional mandatory argument is required")
end

@test_error begin
    @eval @add_kwonly if false
        g(a, b; c=3, d=4) = (a, b, c, d)
    end
end (err) -> begin
    @test err isa ErrorException
    @test contains(err.msg,
                   "add_only does not work with expression if")
end

@test_error begin
    add_kwonly(:(f(x, f(x)) = x))
end (err) -> begin
    @test err isa ErrorException
    @test contains(err.msg,
                   "Not expecting to see: f(x)")
end

let io = IOBuffer()
    showerror(io, Reconstructables.UndefKeywordError(:X))
    msg = String(take!(copy(io)))
    @test contains(msg, "UndefKeywordError: keyword argument X not assigned")
end

end
