
## Introduction

This is a brief tutorial on working with data using the new programming language Julia. In particular, I will use the [JuliaDB](http://juliadb.org/latest/) package to reproduce a well known [tutorial](https://rpubs.com/justmarkham/dplyr-tutorial). The data is some example flight dataset that you can find [here](https://raw.githubusercontent.com/piever/JuliaDBTutorial/master/hflights.csv).

Simply open the link and choose `Save as` from the `File` menu in your browser to save the data to a folder on your computer.

## Loading the data

Loading a csv file is straightforward with JuliaDB:


```julia
using JuliaDB, IndexedTables
flights = loadtable("/home/pietro/Downloads/hflights.csv");
```

Of course, replace the path with the location of the dataset you have just downloaded.

## Filtering the data

In order to select only rows matching certain criteria, use the `filter` function:


```julia
filter(i -> (i.Month == 1) && (i.DayofMonth == 1), flights);
```

To test if one of two conditions is verified:


```julia
filter(i -> (i.UniqueCarrier == "AA") || (i.UniqueCarrier == "UA"), flights)

# in this case, you can simply test whether the `UniqueCarrier` is in a given list:

filter(i -> i.UniqueCarrier in ["AA", "UA"], flights);
```

## Select: pick columns by name

You can use the `select` function to select a subset of columns:


```julia
select(flights, (:DepTime, :ArrTime, :FlightNum))
```




    Table with 227496 rows, 3 columns:
    DepTime  ArrTime  FlightNum
    ───────────────────────────
    1400     1500     428
    1401     1501     428
    1352     1502     428
    1403     1513     428
    1405     1507     428
    1359     1503     428
    1359     1509     428
    1355     1454     428
    1443     1554     428
    1443     1553     428
    1429     1539     428
    1419     1515     428
    ⋮
    1939     2119     124
    556      745      280
    1026     1208     782
    1611     1746     1050
    758      1051     201
    1307     1600     471
    1818     2111     1191
    2047     2334     1674
    912      1031     127
    656      812      621
    1600     1713     1597



Let's select all columns between `:Year` and `:Month` as well as all columns containing "Taxi" or "Delay" in their name:


```julia
cn = colnames(flights)
i1, i2 = find(indexin(cn, [:Year, :DayofMonth]))
taxicols = find(i -> contains(string(i), "Taxi"), cn)
delaycols = find(i -> contains(string(i), "Delay"), cn)
select(flights, Tuple(union(i1:i2, taxicols, delaycols)))
```




    Table with 227496 rows, 7 columns:
    Year  Month  DayofMonth  TaxiIn  TaxiOut  ArrDelay  DepDelay
    ────────────────────────────────────────────────────────────
    2011  1      1           7       13       -10       0
    2011  1      2           6       9        -9        1
    2011  1      3           5       17       -8        -8
    2011  1      4           9       22       3         3
    2011  1      5           9       9        -3        5
    2011  1      6           6       13       -7        -1
    2011  1      7           12      15       -1        -1
    2011  1      8           7       12       -16       -5
    2011  1      9           8       22       44        43
    2011  1      10          6       19       43        43
    2011  1      11          8       20       29        29
    2011  1      12          4       11       5         19
    ⋮
    2011  12     6           4       15       14        39
    2011  12     6           13      9        -10       -4
    2011  12     6           4       12       -12       1
    2011  12     6           3       9        -9        16
    2011  12     6           3       10       -4        -2
    2011  12     6           5       10       0         7
    2011  12     6           5       11       -9        8
    2011  12     6           4       9        4         7
    2011  12     6           4       14       -4        -3
    2011  12     6           3       9        -13       -4
    2011  12     6           3       11       -12       0



## Applying several operations

If one wants to apply several operations one after the other, there are two main approaches:

- nesting
- piping

Let's assume we want to select `UniqueCarrier` and `DepDelay` columns and filter for delays over 60 minutes. The nesting approach would be:



```julia
filter(i -> i.DepDelay > 60, select(flights, (:UniqueCarrier, :DepDelay)))
```




    Table with 10242 rows, 2 columns:
    UniqueCarrier  DepDelay
    ───────────────────────
    "AA"           90
    "AA"           67
    "AA"           74
    "AA"           125
    "AA"           82
    "AA"           99
    "AA"           70
    "AA"           61
    "AA"           74
    "AS"           73
    "B6"           136
    "B6"           68
    ⋮
    "WN"           129
    "WN"           61
    "WN"           70
    "WN"           76
    "WN"           63
    "WN"           144
    "WN"           117
    "WN"           124
    "WN"           72
    "WN"           70
    "WN"           78



For piping, we'll use the excellent [Lazy](https://github.com/MikeInnes/Lazy.jl) package.


```julia
import Lazy
Lazy.@as x flights begin
    select(x, (:UniqueCarrier, :DepDelay))
    filter(i -> i.DepDelay > 60, x)
end
```




    Table with 10242 rows, 2 columns:
    UniqueCarrier  DepDelay
    ───────────────────────
    "AA"           90
    "AA"           67
    "AA"           74
    "AA"           125
    "AA"           82
    "AA"           99
    "AA"           70
    "AA"           61
    "AA"           74
    "AS"           73
    "B6"           136
    "B6"           68
    ⋮
    "WN"           129
    "WN"           61
    "WN"           70
    "WN"           76
    "WN"           63
    "WN"           144
    "WN"           117
    "WN"           124
    "WN"           72
    "WN"           70
    "WN"           78



where the variable `x` denotes our data at each stage. At the beginning it is `flights`, then it only has the two relevant columns and, at the last step, it is filtered.

## Reorder rows

Select `UniqueCarrier` and `DepDelay` columns and sort by `DepDelay`:


```julia
sort(flights, :DepDelay, select = (:UniqueCarrier, :DepDelay))
```




    Table with 227496 rows, 2 columns:
    UniqueCarrier  DepDelay
    ───────────────────────
    "OO"           -33
    "MQ"           -23
    "XE"           -19
    "XE"           -19
    "CO"           -18
    "EV"           -18
    "XE"           -17
    "CO"           -17
    "XE"           -17
    "MQ"           -17
    "XE"           -17
    "DL"           -17
    ⋮
    "US"           #NA
    "US"           #NA
    "US"           #NA
    "WN"           #NA
    "WN"           #NA
    "WN"           #NA
    "WN"           #NA
    "WN"           #NA
    "WN"           #NA
    "WN"           #NA
    "WN"           #NA



or, in reverse order:


```julia
sort(flights, :DepDelay, select = (:UniqueCarrier, :DepDelay), rev = true)
```




    Table with 227496 rows, 2 columns:
    UniqueCarrier  DepDelay
    ───────────────────────
    "AA"           #NA
    "AA"           #NA
    "B6"           #NA
    "B6"           #NA
    "B6"           #NA
    "CO"           #NA
    "CO"           #NA
    "CO"           #NA
    "CO"           #NA
    "CO"           #NA
    "CO"           #NA
    "CO"           #NA
    ⋮
    "CO"           -17
    "XE"           -17
    "XE"           -17
    "US"           -17
    "EV"           -17
    "CO"           -18
    "EV"           -18
    "XE"           -19
    "XE"           -19
    "MQ"           -23
    "OO"           -33



## Add new variables
Use the `pushcol` function to add a column to an existing dataset:


```julia
distance, airtime = columns(flights, (:Distance, :AirTime))
pushcol(flights, :Speed, distance ./ airtime .* 60);
```

If you need to add the new column to the existing dataset:


```julia
distance, airtime = columns(flights, (:Distance, :AirTime))
flights = pushcol(flights, :Speed, distance ./ airtime .* 60);
```

## Reduce variables to values

To get the average delay, we first filter away datapoints where `ArrDelay` is missing, then group by `:Dest`, select `:ArrDelay` and compute the mean:


```julia
groupby(@NT(avg_delay = mean∘dropna), flights, :Dest, select = :ArrDelay)
```




    Table with 116 rows, 2 columns:
    [1mDest   [22mavg_delay
    ────────────────
    "ABQ"  7.22626
    "AEX"  5.83944
    "AGS"  4.0
    "AMA"  6.8401
    "ANC"  26.0806
    "ASE"  6.79464
    "ATL"  8.23325
    "AUS"  7.44872
    "AVL"  9.97399
    "BFL"  -13.1988
    "BHM"  8.69583
    "BKG"  -16.2336
    ⋮
    "SJU"  11.5464
    "SLC"  1.10485
    "SMF"  4.66271
    "SNA"  0.35801
    "STL"  7.45488
    "TPA"  4.88038
    "TUL"  6.35171
    "TUS"  7.80168
    "TYS"  11.3659
    "VPS"  12.4572
    "XNA"  6.89628



Using `summarize`, we can summarize several columns at the same time:


```julia
summarize(mean∘dropna, flights, :Dest, select = (:Cancelled, :Diverted))

# For each carrier, calculate the minimum and maximum arrival and departure delays:

cols = Tuple(find(i -> contains(string(i), "Delay"), colnames(flights)))
summarize(@NT(min = minimum∘dropna, max = maximum∘dropna), flights, :UniqueCarrier, select = cols)
```




    Table with 15 rows, 5 columns:
    [1mUniqueCarrier  [22mArrDelay_min  DepDelay_min  ArrDelay_max  DepDelay_max
    ─────────────────────────────────────────────────────────────────────
    "AA"           -39           -15           978           970
    "AS"           -43           -15           183           172
    "B6"           -44           -14           335           310
    "CO"           -55           -18           957           981
    "DL"           -32           -17           701           730
    "EV"           -40           -18           469           479
    "F9"           -24           -15           277           275
    "FL"           -30           -14           500           507
    "MQ"           -38           -23           918           931
    "OO"           -57           -33           380           360
    "UA"           -47           -11           861           869
    "US"           -42           -17           433           425
    "WN"           -44           -10           499           548
    "XE"           -70           -19           634           628
    "YV"           -32           -11           72            54



For each day of the year, count the total number of flights and sort in descending order:


```julia
Lazy.@as x flights begin
    groupby(length, x, :DayofMonth)
    sort(x, :length, rev = true)
end
```




    Table with 31 rows, 2 columns:
    DayofMonth  length
    ──────────────────
    28          7777
    27          7717
    21          7698
    14          7694
    7           7621
    18          7613
    6           7606
    20          7599
    11          7578
    13          7546
    10          7541
    17          7537
    ⋮
    25          7406
    16          7389
    8           7366
    12          7301
    4           7297
    19          7295
    24          7234
    5           7223
    30          6728
    29          6697
    31          4339



For each destination, count the total number of flights and the number of distinct planes that flew there


```julia
groupby(@NT(flight_count = length, plane_count = length∘union), flights, :Dest, select = :TailNum)
```




    Table with 116 rows, 3 columns:
    [1mDest   [22mflight_count  plane_count
    ────────────────────────────────
    "ABQ"  2812          716
    "AEX"  724           215
    "AGS"  1             1
    "AMA"  1297          158
    "ANC"  125           38
    "ASE"  125           60
    "ATL"  7886          983
    "AUS"  5022          1015
    "AVL"  350           142
    "BFL"  504           70
    "BHM"  2736          616
    "BKG"  110           63
    ⋮
    "SJU"  391           115
    "SLC"  2033          368
    "SMF"  1014          184
    "SNA"  1661          67
    "STL"  2509          788
    "TPA"  3085          697
    "TUL"  2924          771
    "TUS"  1565          226
    "TYS"  1210          227
    "VPS"  880           224
    "XNA"  1172          177



## Window functions

In the previous section, we always applied functions that reduced a table or vector to a single value.
Window functions instead take a vector and return a vector of the same length, and can also be used to
manipulate data. For example we can rank, within each `UniqueCarrier`, how much
delay a given flight had and figure out the day and month with the two greatest delays:


```julia
#using StatsBase
#fc = filter(t->!isnull(t.DepDelay), flights)
#gfc = groupby(fc, :UniqueCarrier, select = (:Month, :DayofMonth, :DepDelay), flatten = true) do dd
#    rks = ordinalrank([i.DepDelay for i in dd], rev = true)
#    sort(dd[rks .<= 2], by =  i -> i.DepDelay, rev = true)
#end;
```

Though in this case, it would have been simpler to use Julia partial sorting:


```julia
groupby(fc, :UniqueCarrier, select = (:Month, :DayofMonth, :DepDelay), flatten = true) do dd
    select(dd, 1:2, by = i -> i.DepDelay, rev = true)
end
```




    Table with 30 rows, 4 columns:
    [1mUniqueCarrier  [22mMonth  DayofMonth  DepDelay
    ──────────────────────────────────────────
    "AA"           12     12          970
    "AA"           11     19          677
    "AS"           2      28          172
    "AS"           7      6           138
    "B6"           10     29          310
    "B6"           8      19          283
    "CO"           8      1           981
    "CO"           1      20          780
    "DL"           10     25          730
    "DL"           4      5           497
    "EV"           6      25          479
    "EV"           1      5           465
    ⋮
    "OO"           4      4           343
    "UA"           6      21          869
    "UA"           9      18          588
    "US"           4      19          425
    "US"           8      26          277
    "WN"           4      8           548
    "WN"           9      29          503
    "XE"           12     29          628
    "XE"           12     29          511
    "YV"           4      22          54
    "YV"           4      30          46



For each month, calculate the number of flights and the change from the previous month


```julia
using ShiftedArrays
y = groupby(length, flights, :Month)
lengths = columns(y, :length)
pushcol(y, :change, lengths .- lag(lengths))
```




    Table with 12 rows, 3 columns:
    [1mMonth  [22mlength  change
    ──────────────────────
    1      18910   missing
    2      17128   -1782
    3      19470   2342
    4      18593   -877
    5      19172   579
    6      19600   428
    7      20548   948
    8      20176   -372
    9      18065   -2111
    10     18696   631
    11     18021   -675
    12     19117   1096


