# MotoServer

Mock AWS services with `moto_server`

[![Build Status](https://travis-ci.org/invenia/MotoServer.jl.svg?branch=master)](https://travis-ci.org/invenia/MotoServer.jl)
[![codecov.io](http://codecov.io/github/invenia/MotoServer.jl/coverage.svg?branch=master)](http://codecov.io/github/invenia/MotoServer.jl?branch=master)

## Requirements

MotoServer.jl requires the Python package `moto[server]`, which can be installed with `pip` (prior to the `moto[server]` extra being added, the server was available in the `moto` package).

The `moto_server` executable must be accessible on the `PATH` (this should happen by default when it is installed).

## Usage

```julia
# this runs a `moto_server` on PROXY_HOST:PROXY_PORT, serving the S3 API
ms = MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="s3")

# run AWS code, configuring the AWS client to point to PROXY_HOST:PROXY_PORT

# the server can be manually killed or left to be finalized, 
# but it'll hold onto the port until then
kill(ms)
```

`PROXY_HOST:PROXY_PORT` defaults to `127.0.0.1:5000`, which is also `moto_server`'s default.

`service` defaults to `""`, and will have whatever behaviour `moto_server` has when no argument is passed to it (this appears to be undefined). 
