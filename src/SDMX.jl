# Interface for downloading data from ECB SDMX 2.1 RESTfut API

using HTTP, JSON3
const SMDX_API_url="https://sdw-wsrest.ecb.europa.eu/service/"
include("TablesInterface.jl")

# flowRef/key?parameters
# startPeriod=value&endPeriod=value&updatedAfter=value&firstNObservations=value&lastNObservations=value&detail=value&includeHistory=value

# Get dataflows. Response in xml...
function dataflows()
    HTTP.get("https://sdw-wsrest.ecb.europa.eu/service/dataflow").body    
end

HTTP.get("https://sdw-wsrest.ecb.europa.eu/service/datastructure/ECB?references=dataflow")

# Download dataflows
function downloaddataflow(dtflow::String;startPeriod::Date)

        HTTP.get(SMDX_API_url*"data/"*dtflow)

end

#=
Las queries para cada DataFlow van seguidos por los valores de las dimensiones separados por puntos. 
Si se quiere obviar una dimensión se deja en blanco
La respuesta incluye: 
    header: datos generales de la query
    dataSets: los datos de las observaciones con la siguientes estructura anidada (para TimeSeries):
        Categorías de dimensiones : String separado por : con el índice de la DIMENSIÓN de la SERIE correspondiente
            Atributos: Vector con los valores de cada ATRIBUTO del SERIE
            Observaciones: Diccionario con "ind => vector" con el índice del vector de fechas y el array con atributos de la observación (includo valor)
    structure: incluye los valores para los índices en dataSets:
        - Dimensiones (series y observaciones)
        - Atributos (series y observaciones)

NOTA: Pensar si es mejor solicitar los datos como "AllDimensions" para que no agrupe las observaciones por fechas -> Sí
=#

# Balances
HTTP.get(SMDX_API_url*"data/CBD2/Q.IE.W0.67._Z._Z.A.F.._X..._Z.LE._T.EUR?startPeriod=2014&format=jsondata")

# PyGs of Ireland
resp = HTTP.get(SMDX_API_url*"data/CBD2/Q.IE.W0.67._Z._Z.A.F.._X.ALL.._Z.T._T.EUR?startPeriod=2014&dimensionAtObservation=AllDimensions&format=jsondata")
js = JSON3.read(resp.body)

l = length(js.structure.dimensions.observation) # Number of dimensions

function getseries(js::JSON3.Object) # Table structured in rows. ToDO -> Tables.jl 

    dimlength = [length(i.values) for i in js.structure.dimensions.observation] # Number of possible values in each dimension

    mask = dimlength .> 1 

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
    push!(obs,(;zip(headers,[dimdesc[mask]...,value])...))  # Rows as Nametuples for Tables.jl com
    end

    # dimensions
    alldims = Dict{String,Vector{String}}()

    for i in js.structure.dimensions.observation
        alldims[i["name"]] = [v["name"] for v in i.values]
    end

    SDMXdata(headers,obs,alldims) # Including headers, observation and all dimensions data
end