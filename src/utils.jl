using Downloads

# WARNING: THIS FILE IS WORK-IN-PROGRESS

#--------------------------------------------------------------------
# Metadata info: dimensions
#--------------------------------------------------------------------
function listdimensions(apiurl::String, dataflow::String)

    io = IOBuffer()
    resp = Downloads.download(apiurl*"data/"*dataflow*"?detail=serieskeysonly&lastNObservations=1&format=jsondata",io) |> take!

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
    io=IOBuffer()
    return Downloads.download(apiurl*database*query,io) |> take! |> SDMX.read(alldims=false)   
end
