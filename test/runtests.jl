using MotoServer
using LibCURL
using Base.Test

const PROXY_HOST = "127.0.0.1"
const PROXY_PORT = UInt(9000)
const PROXY_URL = "$PROXY_HOST:$PROXY_PORT"

const EC2_TEST_URL = "http://ec2.amazonaws.com/?Action=DescribeInstances"
const S3_TEST_URL = "s3.amazonaws.com"

function curl_silencer(curlbuf::Ptr{Void}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Void})
    sz = s * n

    sz::Csize_t
end

c_curl_silencer = cfunction(curl_silencer, Csize_t, (Ptr{Void}, Csize_t, Csize_t, Ptr{Void}))

function response_code(url::String)
    curl = curl_easy_init()

    curl_easy_setopt(curl, CURLOPT_URL, url)
    curl_easy_setopt(curl, CURLOPT_PROXY, PROXY_URL)
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_silencer)

    res = curl_easy_perform(curl)

    http_code = Array(Clong, 1)
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)

    curl_easy_cleanup(curl)

    return http_code[1]
end

@testset "working (s3)" begin
    ms = MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="s3")

    @test response_code(S3_TEST_URL) == 200

    kill(ms)
end

@testset "working (no service specified)" begin
    ms = MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT)

    @test response_code(EC2_TEST_URL) == 500

    kill(ms)
end

@testset "working (ec2)" begin
    ms = MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="ec2")

    @test response_code(EC2_TEST_URL) == 200

    kill(ms)
end

@testset "failure (bind collision)" begin
    ms = MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="ec2")

    @test_throws ErrorException MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT)

    kill(ms)
end
