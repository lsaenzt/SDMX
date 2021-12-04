module SDMX

using JSON3, OrderedCollections
using Tables, PrettyTables
export headers, dimensions
#--------------------------------------------------------------------
# Tables.jl implementation
#--------------------------------------------------------------------

struct Datatable <:Tables.AbstractRow
    name::String
    headers::Vector{Symbol}
    data::Vector{Any}
    dimensions::OrderedDict{String,Vector{String}}
end

# Declare that SDMXdata is a table
Tables.istable(::Type{<:Datatable}) = true

# getter methods to avoud getproperty clash
name(dt::Datatable) = getfield(dt, :name)
headers(dt::Datatable) = getfield(dt, :headers)
data(dt::Datatable) = getfield(dt, :data)
dimensions(dt::Datatable) = getfield(dt, :dimensions)

# Tables.rows implementation. Fallback definitions are valid
Tables.rowaccess(::Type{<:Datatable}) = true
Tables.rows(dt::Datatable) = data(dt)

# Complete Abstractrow interface
Tables.getcolumn(dt::Datatable, i::Int) = [row[i] for row in data(dt)]
Tables.getcolumn(dt::Datatable, nm::Symbol) = [row[nm] for row in data(dt)]	
Tables.columnnames(dt::Datatable) = headers(dt)

#--------------------------------------------------------------------
# Datatable prettyprinting
#--------------------------------------------------------------------

function Base.show(io::IO,dt::Datatable) 
    println("\n ",length(headers(dt)),"x",length(data(dt))," SDMX.Datatable")
    printstyled(" ",name(dt),"\n"; bold=true)
    pretty_table(dt; alignment = :l)
end

#--------------------------------------------------------------------
# Datatable generation
#--------------------------------------------------------------------

function read(js::Union{Vector{UInt8},String}; alldims=true)

    ds = JSON3.read(js)

    dims = OrderedDict() # Collects 'Series' (if any) and 'Observations'
    mask = Dict()

    for (k,v) in ds.structure.dimensions
        if alldims
            dims[k] = v
            mask[k] = Colon()
        else
            m = [(length(i["values"])>1) | (haskey(i,"role")) for i in v] .== true # BitVector vector for filtering
            dims[k] = v[m]
            mask[k] = m
        end
    end

    # Headers vector
    headers = Vector{Symbol}() 
    for v in values(dims)
        for i in v
            push!(headers, Symbol(i["name"]))
        end
    end
    push!(headers,:Value)

    # Rows of observations
    obs=[]
    if haskey(dims,:series)
        
        for (kₛ,vₛ) in ds.dataSets[1].series
          serieskey = parse.(Int,split(string(kₛ),":")).+1 #Transforms dimension into a 1-index Array
          serieskey = serieskey[mask[:series]] # Filters descriptive dimensions if alldims=false
          dimdesc = Vector{String}(undef,length(serieskey))
          for (i,n) in enumerate(serieskey)
            dimdesc[i] = dims[:series][i][:values][n]["name"]
          end
          for (kₒ,vₒ) in vₛ["observations"]
            obsdim = dims[:observation][1]["values"][parse(Int,string(kₒ))+1]["name"]
            dimvalues = [dimdesc...,obsdim]
            row = [dimvalues...,vₒ[1]]
            push!(obs,(;zip(headers,row)...))
          end
        end

    else         
        for (k,v) in ds.dataSets[1].observations
            dimkey = parse.(Int,split(string(k),":")).+1 # Transforms dimension into a 1-index Array
            dimkey = dimkey[mask[:observation]]
            dimdesc = Vector{String}(undef,length(dimkey))
                for (i,n) in enumerate(dimkey)
                    dimdesc[i]=   dims[:observation][i]["values"][n]["name"]
                end
            value = v[1]
            push!(obs,(;zip(headers,[dimdesc...,value])...))  # Rows as Nametuples for Tables.jl
        end
    end

    # Collect info of all dimensions
    dims_all = OrderedDict() 
    for v in values(ds.structure.dimensions)
        for i in v
            dims_all[i["name"]] = [j["name"] for j in i["values"]]
        end
    end     

    # Create datatable
    Datatable(ds.structure.name, 
              headers,
              obs,
              dims_all) # Including headers, observation and all dimensions data
end

end #Module
