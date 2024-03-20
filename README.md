# LengthAreaVolume.jl

a simple module to compute and convert units between length, area and volume.

## Defination

|Length|Area|Volume|
|:-:|:-:|:-:|
|Gigameter|Gigameter2|Gigameter3|
|Kilometer|Kilometer2|Kilometer3|
|Meter|Meter2|Meter3|
|Decimeter|Decimeter2|Decimeter3|
|Centimeter|Centimeter2|Centimeter3|
|Millimeter|Millimeter2|Millimeter3|
|Macrometer|Macrometer2|Macrometer3|
|Nanometer|Nanometer2|Nanometer3|

## Calculation

`Length` * `Length` --> `Area`

`Length` * `Area` --> `Volume`

`Length` * `Length` * `Length` --> `Volume`

## Example

```julia
using LengthAreaVolume

len1 = Meter(1)
len2 = Centimeter(23)
len3 = Micrometer(4567)

println(len1+len2+len3)

area = len1 * len2
println(area)

volume = len1 * len2 * len3
println(volume)

println(numberwithunit(volume, Centimeter3))
println(round(volume, Centimeter3))
println(betterunit(volume))
```

and the results are:
```txt
Micrometer(1234567)
Centimeter2(2300)
Micrometer3(1050410000000000)
1050.41
Centimeter3(1050)
Millimeter3(1050410)
```
