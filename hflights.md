# Data wrangling with JuliaDB

## Introduction

This is a brief tutorial on working with data using the new programming language Julia. In particular, I will use the [JuliaDB](http://juliadb.org/latest/) package to reproduce a well known [tutorial](https://rpubs.com/justmarkham/dplyr-tutorial). The data is some example flight dataset that you can find [here](https://raw.githubusercontent.com/piever/JuliaDBTutorial/master/hflights.csv).

Simply open the link and choose `Save as` from the `File` menu in your browser to save the data to a folder on your computer.

## Loading the data

Loading a csv file is straightforward with JuliaDB:

```julia
using JuliaDB
flights = loadtable("/Users/pietro/Downloads/hflights.csv")
```

Of course, replace the path with the location of the dataset you have just downloaded.

## Filtering the data

In order to select only rows matching certain critera, use the `filter` function:

```julia
filter(i -> (i.Month == 1) && (i.DayofMonth == 1), flights)
```

To test if one of two conditions is verified:

```julia
filter(i -> (i.UniqueCarrier == "AA") || (i.UniqueCarrier == "UA"), flights)
```

In this case, you can simply test whether the `UniqueCarrier` is in a given list:


```julia
filter(i -> i.UniqueCarrier in ["AA", "UA"], flights)
```

## Select: pick columns by name

You can use the `select` function to select a subset of columns:

```julia
select(flights, (:DepTime, :ArrTime, :FlightNum))
```

You can use `colindex` to select multiple contiguous columns: 

```julia
cn = colnames(flights)
i1, i2 = findfirst(cn, :Year) , findfirst(cn, :DayofMonth)
taxicols = find(i -> contains(string(i), "Taxi"), cn)
delaycols = find(i -> contains(string(i), "Delay"), cn)
select(flights, Tuple(union(i1:i2, taxicols, delaycols)))
```

## Applying several operations

If one wants to apply several operations one after the other, there are two main approaches: nesting and piping.

Let's assume we want to select `UniqueCarrier` and `DepDelay` columns and filter for delays over 60 minutes. The nesting approach would be:

```julia
filter(i -> i.DepDelay > 60, select(flights, (:UniqueCarrier, :DepDelay)))
```

## Piping

For piping, we'll use the excellent [Lazy](https://github.com/MikeInnes/Lazy.jl) package.

```julia
using Lazy
@as x flights begin
    select(x, (:UniqueCarrier, :DepDelay))
    filter(i -> i.DepDelay > 60, x)
end
```

where the variable `x` denotes our data at each stage. At the beginning it is `flights`, then it only has the two relevant columns and, at the last step, it is filtered.

## Reorder rows

Select `UniqueCarrier` and `DepDelay` columns and sort by `DepDelay`:

```julia
sort(flights, :DepDelay, select = (:UniqueCarrier, :DepDelay))
```

or, in reverse order:

```julia
sort(flights, :DepDelay, select = (:UniqueCarrier, :DepDelay), rev = true)
```

## Add new variables

```julia
distance, airtime = columns(flights, (:Distance, :AirTime))
pushcol(flights, :Speed, distance ./ airtime .* 60)
```

If you need to add the new column to the existing dataset:

```julia
distance, airtime = columns(flights, (:Distance, :AirTime))
flights = pushcol(flights, :Speed, distance ./ airtime .* 60)
```

## Reduce variables to values

To get the average delay, we first filter away datapoints where `ArrDelay` is missing, then group by `:Dest`, select `:ArrDelay` and compute the mean:

```julia
@as x flights begin
    filter(i -> !isnull(i.ArrDelay), x)
    groupby(@NT(avg_delay = mean), x, :Dest, select = :ArrDelay)
end
```

Using `summarize`, we can summarize several columns at the same time:

```julia
@as x flights begin
    filter(i -> !isnull(i.Cancelled) && !isnull(i.Diverted), x)
    summarize(mean, x, :Dest, select = (:Cancelled, :Diverted))
end
```
