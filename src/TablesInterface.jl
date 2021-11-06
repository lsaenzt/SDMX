using Tables, PrettyTables

struct SDMXdata
    headers::Vector{Symbol}
    data::Vector{Any}
    dimensions::Dict{String,Vector{String}}
end

Base.show(io::IO,sd::SDMXdata) = print(io,@pt sd)

# Declare that SDMXdata is a table

Tables.istable(::Type{<:SDMXdata}) = true
# getter methods to avoud getproperty clash
headers(sd::SDMXdata) = getfield(sd, :headers)
data(sd::SDMXdata) = getfield(sd, :data)

# Tables.rows implementation
Tables.rowaccess(::Type{<:SDMXdata}) = true
Tables.rows(sd::SDMXdata) = data(sd)