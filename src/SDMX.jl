module SDMX
# Interface for downloading data from ECB SDMX 2.1 RESTfut API
using HTTP, JSON3, Dates, StructTypes, OrderedCollections
using Tables, PrettyTables

include("./TablesInterface.jl")

mutable struct Header
    id::String
    test::Bool
    prepared::String # Change to Date
    sender

    Header() = new()
end

# Note: loading in data here changes order of data. RETHINK
mutable struct DataSet
    action::String
    validfrom::String # Change to Date
    # For timeseries
    observation   
    series
    # For flat file
    observations

    DataSet() = new()
end

mutable struct Structure
    links
    name::String
    dimensions
    attributes
    
    Structure() = new()
end

mutable struct Data
    header::Header
    dataSets::Vector{DataSet}
    structure::Structure

    Data() = new()
end

StructTypes.StructType(::Type{Data}) = StructTypes.Mutable()
StructTypes.StructType(::Type{DataSet}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Header}) = StructTypes.Mutable()
StructTypes.StructType(::Type{Structure}) = StructTypes.Mutable()

#--------------------------------------------------------------------
# Metadata info: dimensions
#--------------------------------------------------------------------

function listdimensions(apiurl::String, dataflow::String)

    resp = HTTP.get(apiurl*"data/"*dataflow*"?detail=serieskeysonly&lastNObservations=1&format=jsondata").body

    ds = JSON3.read(resp).structure.dimensions.series

    dim = OrderedDict()

    for dsᵢ in ds
        dim[dsᵢ.name] = NamedTuple(Symbol(j.id) => j.name for j in dsᵢ.values) 
    end

    dim
end

#--------------------------------------------------------------------
# Basic Data download
#--------------------------------------------------------------------

function getseries(apiurl::String, database::String, keys::Dict{Symbol, String};
                 dimensionAtObservation="AllDimensionsdetail")
 
    query = join(values(keys),".") # TODO: Deal with several values (ie. ES+PT+IE)
    return HTTP.get(apiurl*database*query).body |> JSON3.read(SMDX.Data)    
end

#--------------------------------------------------------------------
# Datatable generation
#--------------------------------------------------------------------

function read(js::Union{Vector{UInt8},String}; alldims=true)

    ds = JSON3.read(js, Data)

    dims_all = OrderedDict() # Collects info of all dimensions before filtering if alldims
    for v in values(ds.structure.dimensions)
        for i in v
            dims_all[i["name"]] = [j["name"] for j in i["values"]]
        end
    end
      
    dims = ds.structure.dimensions # Collects 'Series' (if any) and 'Observations'

    mask = Dict()
    for (k,v) in dims
        if alldims == false
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
    if haskey(dims,"series")
        
        for (kₛ,vₛ) in ds.dataSets[1].series
          serieskey = parse.(Int,split(string(kₛ),":")).+1 #Transforms dimension into a 1-index Array
          serieskey = serieskey[mask["series"]] # Filters descriptive dimensions if alldims=false
          dimdesc = Vector{String}(undef,length(serieskey))
          for (i,n) in enumerate(serieskey)
            dimdesc[i] = dims["series"][i]["values"][n]["name"]
          end
          for (kₒ,vₒ) in vₛ["observations"]
            obsdim = dims["observation"][1]["values"][parse(Int,kₒ)+1]["name"]
            dimvalues = [dimdesc...,obsdim]
            row = [dimvalues...,vₒ[1]]
            push!(obs,(;zip(headers,row)...))
          end
        end

    else         
        for (k,v) in ds.dataSets[1].observations
            dimkey = parse.(Int,split(string(k),":")).+1 # Transforms dimension into a 1-index Array
            dimkey = dimkey[mask["observation"]]
            dimdesc = Vector{String}(undef,length(dimkey))
                for (i,n) in enumerate(dimkey)
                    dimdesc[i]=   dims["observation"][i]["values"][n]["name"]
                end
            value = v[1]
            push!(obs,(;zip(headers,[dimdesc...,value])...))  # Rows as Nametuples for Tables.jl
        end
    end

    datatable(ds.structure.name, 
              headers,
              obs,
              dims_all) # Including headers, observation and all dimensions data
end

end #Module