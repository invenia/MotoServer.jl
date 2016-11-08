module MotoServer

export MockAWSServer

const LOCALHOST = "127.0.0.1"
const DEFAULT_PORT = UInt(5000)

type MockAWSServer
    proc::Base.Process
    perr::Pipe
end

function MockAWSServer(;
    host::String=LOCALHOST,
    port::UInt=DEFAULT_PORT,
    service::String=""
)
    perr = Pipe()
    Base.link_pipe(perr, julia_only_read=true, julia_only_write=false)

    proc = spawn(pipeline(`moto_server --host $host --port $port $service`, stderr=perr))

    # we need this many bytes to know if the server is running or not based on output
    Base.wait_readnb(perr, 12)
    err_text = String(readavailable(perr))

    # checking two conditions because process_running might have a race condition?
    # it looked that way while testing
    if !process_running(proc) || !contains(err_text, "unning")
        # start reading async+blocking, then yield to the reading Task
        # this ensures we get everything when the pipe closes
        output = @async readstring(perr)
        close(perr)
        err_text *= wait(output)
        kill(proc)

        error("Failed to start a moto server:\n$err_text)")
    end

    m = MockAWSServer(proc, perr)
    finalizer(m, kill)

    return m
end

function MockAWSServer(f::Function, args...; kwargs...)
    m = MockAWSServer(args...; kwargs...)

    local ret
    try
        ret = f(m)
    finally
        kill(m)
    end

    return ret
end

function Base.kill(m::MockAWSServer)
    if process_running(m.proc) && !process_exited(m.proc)
        close(m.perr)

        # without this check, there was an AssertionError: race condition?
        if m.proc.handle != C_NULL
            kill(m.proc, 2)  # SIGINT / CTRL+C
        end
    end

    nothing
end

end # module
