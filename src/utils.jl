using Downloads

# WARNING: THIS FILE IS WORK-IN-PROGRESS

#--------------------------------------------------------------------
# Metadata info: dimensions
#--------------------------------------------------------------------
function listdimensions(apiurl::String, dataflow::String)

    io = IOBuffer()
    resp = Downloads.download(apiurl * "data/" * dataflow * "?detail=serieskeysonly&lastNObservations=1&format=jsondata", io) |> take!

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

"""Generates a SDMX API compliant url
#kwargs
    filter::Union{nothing,NamedTuple},
    updatedAfter::DateTime,
    firstNObservations::Int,
    lastNObservations::Int,
    dimensionAtObservation,
    attributes = "dsd",
    measures = "all",
    includeHistory = false
"""
function generateurl(;context = "*", agencyID = "*", resourceID = "*", version = "*", key::String="*", kwargs...) # TODO: substitute query args by kwargs...
    baseurl = join(["https://ws-entry-point/data/",context,agencyID,resourceID,version,key],"/")
    query = "/?"*join([String(k)*"="*kwargs[k] for k in keys(kwargs)],"&")
end


""" Generates key part of url from a dictionary"""
function generatekey(dims)
    key = ""
    for v in dims
        key = key*join[v,"+"]*"." # FIXME = sobraría un punto??
    end
end


""" Fetch data and creates a SDMX.Datatable"""
function getseries(url)
    io = IOBuffer()
    return Downloads.download(url, io) |> take! |> SDMX.read(alldims = false)
end
