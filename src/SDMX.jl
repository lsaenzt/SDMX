# Interface for downloading data from ECB SDMX 2.1 RESTfut API

using HTTP, JSON3

# url for ECB data
const SMDX_API_url="https://sdw-wsrest.ecb.europa.eu/service/"

include("TablesInterface.jl")

# flowRef/key?parameters
# startPeriod=value&endPeriod=value&updatedAfter=value&firstNObservations=value&lastNObservations=value&detail=value&includeHistory=value

# Get dataflows. Response in xml...
function dataflows()
    HTTP.get(SMDX_API_url*"dataflow").body    
end

HTTP.get("https://sdw-wsrest.ecb.europa.eu/service/datastructure/ECB?references=dataflow")

# Download dataflows
function downloaddataflow(dtflow::String;startPeriod::Date)
        HTTP.get(SMDX_API_url*"data/"*dtflow)
end

#--------------------------------------------------------------------
# Basic Data download
#--------------------------------------------------------------------

function getseries(apiurl::String, database::string, dimensions::Dict{Symbol, String})
 
    query = join(values(dimensions),".") # TODO: Deal with several values (ie. ES+PT+IE)

    url = apiurl*database*query
    
end

#--------------------------------------------------------------------
# Working example
#--------------------------------------------------------------------

# Balance Sheet
HTTP.get(SMDX_API_url*"data/CBD2/Q.IE.W0.67._Z._Z.A.F.._X..._Z.LE._T.EUR?startPeriod=2014&format=jsondata")

# P&L Bank of Ireland
resp = HTTP.get(SMDX_API_url*"data/CBD2/Q.IE.W0.67._Z._Z.A.F.._X.ALL.._Z.T._T.EUR?startPeriod=2014&dimensionAtObservation=AllDimensions&format=jsondata")
js = JSON3.read(resp.body)

function getseries(js::JSON3.Object)

    dimlength = [length(i.values) for i in js.structure.dimensions.observation] # Number of possible values in each dimension

    mask = dimlength .> 1 # Only including dimensions with more than 1 attribute

    # Headers vector
    headers = Vector{Symbol}()    
    for i in js.structure.dimensions.observation[mask]
        push!(headers, Symbol(i.name))
    end
    push!(headers,:Value)

    # Rows of observations    
    obs=[]
    for (k,v) in js.dataSets[1].observations
    dims = parse.(Int,split(string(k),":")).+1 #Transforms dimension into a 1-index Array
    dimdesc = Vector{String}(undef,length(dims))

        for i in 1:length(dims)
            dimdesc[i]=js.structure.dimensions.observation[i].values[dims[i]].name
        end

    value = v[1]
    push!(obs,(;zip(headers,[dimdesc[mask]...,value])...))  # Rows as Nametuples for Tables.jl
    end

    # Get all dimensions
    alldims = Dict{String,Vector{String}}()

    for i in js.structure.dimensions.observation
        alldims[i["name"]] = [v["name"] for v in i.values]
    end

    SDMXdata(headers,obs,alldims) # Including headers, observation and all dimensions data
end