module LengthAreaVolume

import Base: +, -, *, /, promote_rule, round, floor, ceil

const _MAGNITURE_PREFIX = (:Giga, :Mega, :Kilo, Symbol(""), :Deci, :Centi, :Milli, :Micro, :Nano)
const _PREFIX_POWER = (9, 6, 3, 0, -1, -2, -3, -6, -9)
_getunit(p::Symbol, s::Symbol) = Symbol(uppercasefirst(String(Symbol(p, s))))

# * Length
# _LENGTH_TYPE_LIST = (:Kilometer, :Meter, :Decimeter, :Centimeter, :Millimeter, :Micrometer, :Nanometer)
const _LENGTH_TYPE_LIST = _getunit.(_MAGNITURE_PREFIX, :meter)

const _LENGTH_UNIT_POWER = _PREFIX_POWER

export Length

eval(Meta.parse("export $(join(_LENGTH_TYPE_LIST, ", "))"))

abstract type Length <: Any end

for sym in _LENGTH_TYPE_LIST
    # type define
    @eval struct $sym <: Length
        value::Int
    end
    # basic calculation
    @eval begin
        $sym(a::$sym) = a
        +(a::$sym, b::$sym) = $sym(a.value + b.value)
        -(a::$sym, b::$sym) = $sym(a.value - b.value)
        *(a::$sym, b::Integer) = $sym(a.value * b)
        *(a::Integer, b::$sym) = $sym(b.value * a)
        /(a::$sym, b::$sym) = a.value / b.value
    end
end

# * Area and Volume

abstract type Area <: Any end
abstract type Volume <: Any end

export Area, Volume

const _AREA_TYPE_LIST = _getunit.(_MAGNITURE_PREFIX, :meter2)
const _AREA_UNIT_POWER = _PREFIX_POWER .* 2
const _VOLUME_TYPE_LIST = _getunit.(_MAGNITURE_PREFIX, :meter3)
const _VOLUME_UNIT_POWER = _PREFIX_POWER .* 3

eval(Meta.parse("export $(join(_AREA_TYPE_LIST, ", "))"))
eval(Meta.parse("export $(join(_VOLUME_TYPE_LIST, ", "))"))
export lowerdim, upperdim

for sym in _MAGNITURE_PREFIX
    symlen    = _getunit(sym, :meter)
    symarea   = _getunit(sym, :meter2)
    symvolume = _getunit(sym, :meter3)
    @eval begin
        # type define
        struct $symarea <: Area
            value::Int
        end
        struct $symvolume <: Volume
            value::Int
        end
        lowerdim(::Type{$symarea})   = $symlen
        lowerdim(::Type{$symvolume}) = $symarea
        upperdim(::Type{$symlen})    = $symarea
        upperdim(::Type{$symarea})   = $symvolume
        # basic calculation
        # Area
        $symarea(s::$symarea) = s
        +(s::$symarea, t::$symarea) = $symarea(s.value+t.value)
        -(s::$symarea, t::$symarea) = $symarea(s.value+t.value)
        *(a::Integer, s::$symarea)  = $symarea(a*s.value)
        *(s::$symarea, a::Integer)  = $symarea(a*s.value)
        /(s::$symarea, t::$symarea) = s.value/t.value
        # Volume
        $symvolume(v::$symvolume) = v
        +(v::$symvolume, w::$symvolume) = $symvolume(v.value+w.value)
        -(v::$symvolume, w::$symvolume) = $symvolume(v.value-w.value)
        *(a::Integer, v::$symvolume)  = $symvolume(a*v.value)
        *(v::$symvolume, a::Integer)  = $symvolume(a*v.value)
        /(v::$symvolume, w::$symvolume) = v.value/w.value
        # Length, Area, Volume calculation
        *(a::$symlen, b::$symlen) = $symarea(a.value*b.value)
        *(a::$symlen, s::$symarea) = $symvolume(a.value*s.value)
        *(s::$symarea, a::$symlen) = $symvolume(a.value*s.value)
    end
end

# * promote rule
for i = eachindex(_MAGNITURE_PREFIX), j = eachindex(_MAGNITURE_PREFIX)
    if j >= i
        continue
    end

    isymlen    = _getunit(_MAGNITURE_PREFIX[i], :meter)
    isymarea   = _getunit(_MAGNITURE_PREFIX[i], :meter2)
    isymvolume = _getunit(_MAGNITURE_PREFIX[i], :meter3)

    jsymlen    = _getunit(_MAGNITURE_PREFIX[j], :meter)
    jsymarea   = _getunit(_MAGNITURE_PREFIX[j], :meter2)
    jsymvolume = _getunit(_MAGNITURE_PREFIX[j], :meter3)

    @eval begin
        # promote
        # Length
        promote_rule(::Type{$isymlen}, ::Type{$jsymlen}) = $isymlen
        promote_rule(::Type{$jsymlen}, ::Type{$isymlen}) = $isymlen
        # Area
        promote_rule(::Type{$isymarea}, ::Type{$jsymarea}) = $isymarea
        promote_rule(::Type{$jsymarea}, ::Type{$isymarea}) = $isymarea
        # Volume
        promote_rule(::Type{$isymvolume}, ::Type{$jsymvolume}) = $isymvolume
        promote_rule(::Type{$jsymvolume}, ::Type{$isymvolume}) = $isymvolume
        # unit convert
        $isymlen(t::$jsymlen) = $isymlen(t.value*10^$(_LENGTH_UNIT_POWER[j]-_LENGTH_UNIT_POWER[i]))
        $isymarea(t::$jsymarea) = $isymarea(t.value*10^$(_AREA_UNIT_POWER[j]-_AREA_UNIT_POWER[i]))
        $isymvolume(t::$jsymvolume) = $isymvolume(t.value*10^$(_VOLUME_UNIT_POWER[j]-_VOLUME_UNIT_POWER[i]))
    end
end

export numberwithunit

# * more general setting
for kinds in (:Length, :Area, :Volume)
    for sym in (:(+), :(-), :(*), :(/))
        @eval function $sym(a::$kinds, b::$kinds)
            T = promote_type(typeof(a), typeof(b))
            return $sym(T(a), T(b))
        end
    end
    @eval begin
        function numberwithunit(a::$kinds, S::DataType)
            T = promote_type(typeof(a), S)
            return T(a)/T(S(1))
        end

        function round(a::$kinds, precision::$kinds, r::RoundingMode=RoundNearest)
            T = promote_type(typeof(a), typeof(precision))
            return Base.round(Int, T(a)/T(precision), r)*precision
        end
        ceil(a::$kinds, precision::$kinds) = round(a, precision, RoundUp)
        floor(a::$kinds, precision::$kinds) = round(a, precision, RoundDown)
        round(a::$kinds, T::DataType, r::RoundingMode=RoundNearest) = round(a, T(1), r)
        ceil(a::$kinds, T::DataType) = ceil(a, T(1))
        floor(a::$kinds, T::DataType) = floor(a, T(1))
    end
end

function *(a::Length, b::Area)
    T = promote_type(typeof(a), lowerdim(typeof(b)))
    T2 = upperdim(T)
    return T(a)*T2(b)
end

*(a::Area, b::Length) = *(b, a)

export betterunit

"""
```
betterunit(a)
```

find a better unit expression that make the `value` not too large
"""
function betterunit(a::Length)
    if iszero(a.value)
        return Meter(0)
    end
    T = typeof(a)
    iT = findfirst(==(Symbol(T)), _LENGTH_TYPE_LIST)
    m = _LENGTH_UNIT_POWER[iT]
    v = a.value
    while iszero(v % 10)
        m += 1
        v = v ÷ 10
    end
    iS = findfirst(<(m), _LENGTH_UNIT_POWER)
    S = _LENGTH_TYPE_LIST[iS]
    return round(a, eval(S))
end

function betterunit(a::Area)
    if iszero(a.value)
        return Meter2(0)
    end
    T = typeof(a)
    iT = findfirst(==(Symbol(T)), _AREA_TYPE_LIST)
    m = _AREA_UNIT_POWER[iT]
    v = a.value
    while iszero(v % 10)
        m += 1
        v = v ÷ 10
    end
    iS = findfirst(<(m), _AREA_UNIT_POWER)
    S = _AREA_TYPE_LIST[iS]
    return round(a, eval(S))
end

function betterunit(a::Volume)
    if iszero(a.value)
        return Meter3(0)
    end
    T = typeof(a)
    iT = findfirst(==(Symbol(T)), _VOLUME_TYPE_LIST)
    m = _VOLUME_UNIT_POWER[iT]
    v = a.value
    while iszero(v % 10)
        m += 1
        v = v ÷ 10
    end
    iS = findfirst(<(m), _VOLUME_UNIT_POWER)
    S = _VOLUME_TYPE_LIST[iS]
    return round(a, eval(S))
end


end # module LengthAreaVolume
