using Tables, PrettyTables

struct SDMXdata
    headers::Vector{Symbol}
    data::Vector{Any}
    dimensions::Dict{String,Vector{String}}
end

Base.show(io::IO,sd::SDMXdata) = pretty_tables(sd)

# Declare that SDMXdata is a table

Tables.istable(::Type{<:SDMXdata}) = true
# getter methods to avoud getproperty clash
headers(sd::SDMXdata) = getfield(sd, :headers)
data(sd::SDMXdata) = getfield(sd, :data)
dimensions(sd::SDMXdata) = getfield(ds, :dimensions)

# Tables.rows implementation. Fallback definitions are valid
Tables.rowaccess(::Type{<:SDMXdata}) = true
Tables.rows(sd::SDMXdata) = data(sd)