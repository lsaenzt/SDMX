using Test, Downloads
using SDMX

const ecb_url = "https://sdw-wsrest.ecb.europa.eu/service/"
const flowref = "CBD2/"
const BS = "Q.IE.W0.67._Z._Z.A.F.._X..._Z.LE._T.EUR"
const PL = "Q.IE.W0.67._Z._Z.A.F.._X.ALL.._Z.T._T.EUR"

io = IOBuffer()
flat = Downloads.download(ecb_url*"data/"*flowref*BS*"?startPeriod=2020&dimensionAtObservation=AllDimensions&format=jsondata", io) |> take!
series = Downloads.download(ecb_url*"data/"*flowref*BS*"?startPeriod=2020&format=jsondata", io) |> take!

dt_flat = SDMX.read(flat)
dt_series = SDMX.read(series)

@test SDMX.name(dt_flat) == SDMX.name(dt_series)
@test SDMX.headers(dt_flat) == SDMX.headers(dt_series)
@test SDMX.data(dt_flat) == SDMX.data(dt_series)