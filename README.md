# SDMX
A Tables.jl compliant for reading SDMX files. 
Right now, only 'json' format is supported. Make sure to include 'format = jsondata' in the data request.

```julia
ECB_url = "https://sdw-wsrest.ecb.europa.eu/service/"
HTTP.get(EBC_url*"data/CBD2/Q.IE.W0.67._Z._Z.A.F.._X..._Z.LE._T.EUR?startPeriod=2020&format=jsondata").body |> SDMX.read
```

SDMX.read(js; alldims = true) returns a SDMX.Datatable that can be loaded into a DataFrame, saved with CSV or use any other Tables.jl-ready package

'alldims::Bool' keyword determines the dimensions to be included in the SDMX.Datatable. When set to false only dimensions with more than one value or a specific role are included.

SDMX.dimensions(dt::SDMX.Datatable) returns all dimensions and their possible values, even if 'alldims' is set to false.
