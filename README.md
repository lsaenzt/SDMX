# SDMX
A Tables.jl compliant for reading SDMX files. Right now, only 'dataset' class is supported

```julia
ECB_url = "https://sdw-wsrest.ecb.europa.eu/service/"
HTTP.get(EBC_url*"data/CBD2/Q.IE.W0.67._Z._Z.A.F.._X..._Z.LE._T.EUR?startPeriod=2020&format=jsondata").body |> SDMX.read
```
Result is a SDMX.Datatable that can be loaded into a DataFrame, saved with CSV or use any other Tables.jl-ready package

Additional information can be accesed using:
    - SDMX.dimensions(dt::SDMX.Datatable)

