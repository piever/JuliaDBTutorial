using Weave
weave(joinpath(@__DIR__, "hflights.jmd"), out_path = joinpath(@__DIR__, "docs", "index.html"))