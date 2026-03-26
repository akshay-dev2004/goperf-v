<br>

<img 
  src="https://github.com/user-attachments/assets/917f03ef-29fa-47bf-96fb-a60789cdad4e"
  width="500"
/>
<br><br>
[![GitHub release](https://img.shields.io/github/v/release/infraspecdev/goperf?style=flat-square)](https://github.com/infraspecdev/goperf/releases)
[![CI status](https://img.shields.io/github/actions/workflow/status/infraspecdev/goperf/ci.yml?branch=main&style=flat-square)](https://github.com/infraspecdev/goperf/actions/workflows/ci.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/infraspecdev/goperf?style=flat-square)](https://goreportcard.com/report/github.com/infraspecdev/goperf)

`goperf` is a lightweight, high-performance HTTP load testing and benchmarking tool written in Go. It focuses on closed-loop load testing to help developers quickly validate API performance, measure concurrency limits, and analyze real-world latency metrics like p90 and p99.

## Features

- **Concurrency & Duration Testing:** Test by a strict number of requests or over a sustained duration.
- **Detailed Metrics:** Accurate reporting of TTFB (Time To First Byte) latencies, including min, max, average, p50, p90, and p99 percentiles.
- **CI/CD Ready:** Native JSON output support for easy integration into automated pipelines.
- **Configurable:** Support for complex requests via YAML/JSON configuration files, custom HTTP headers, and payloads.

## Installation

**Linux / macOS**
```bash
curl -sL https://raw.githubusercontent.com/infraspecdev/goperf/main/install.sh | sh
```
**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/infraspecdev/goperf/main/install.ps1 | iex
```
**Build from Source (Requires Go 1.26.1 or newer)**
```bash
git clone https://github.com/infraspecdev/goperf.git
cd goperf
make build
./bin/goperf --help
```

## Usage

`goperf` runs the provided number of requests at the provided concurrency level and prints latency stats.

```text
Usage: goperf run <url> [options...]

Options:
  -n          Number of requests to execute. Default is 1.
  -c          Number of concurrent workers. Default is 1.
  -d          Duration to run the test. When duration is reached, the application
              stops and exits. If duration is specified, -n is ignored. 
              Examples: -d 10s, -d 1m.
  -o          Output format. "text" or "json". Default is text.

  -m          HTTP method, one of GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD.
              Default is GET.
  -H          Custom HTTP header. You can specify as many as needed by repeating the flag.
              For example: -H "Accept: text/html" -H "Content-Type: application/json".
  -b          HTTP request body content.
  -t          Timeout for each request. Default is 10s.
  
  -f          Path to configuration file (JSON/YAML).
  -v          Enable verbose output. Prints every request's latency or error.
```

## Examples

Make 100 requests sequentially:
```bash
goperf run https://httpbin.org/get -n 100
```

Make 1000 requests with 50 concurrent workers:
```bash
goperf run https://httpbin.org/get -n 1000 -c 50
```

Run load test for 30 seconds:
```bash
goperf run https://httpbin.org/get -c 50 -d 30s
```

Make POST request with custom body:
```bash
goperf run https://httpbin.org/post \
    -m POST \
    -b '{"title":"foo","body":"bar"}'
```

Add custom headers:
```bash
goperf run https://httpbin.org/get \
    -H "Accept: application/json" \
    -H "Authorization: Bearer token"
```

Run test using a configuration file:
```bash
goperf run -f load-test.yaml
```

Example `load-test.yaml`:
```yaml
target: "https://httpbin.org/post"
concurrency: 100
duration: "1m"
method: "POST"
headers:
  - "Authorization: Bearer your-token-here"
  - "Content-Type: application/json"
body: '{"test":"data"}'
```

Prevent hanging requests by enforcing a strict per-request timeout:
```bash
goperf run https://httpbin.org/delay/3 -t 2s
```
 Use Verbose Mode for Debugging, print the result and latency of every individual request:
```bash
goperf run https://httpbin.org/get -n 10 -v
```


Output stats as JSON for CI/CD automation:
```bash
goperf run https://httpbin.org/get -n 500 -c 20 -o json
```

## How it Works

- **We measure TTFB (Time To First Byte):** Our timer stops the exact millisecond your server starts sending response headers. We don't include the time it takes to download the actual response body.Because we want to measure how fast your server processes data, not how fast your local internet connection is.

- **Closed-Loop Testing:** `goperf` sends a request, waits for the response, and then sends the next one. If you use `-c 50`, you will have exactly 50 connections open at all times.

- **The "Coordinated Omission" :** Because our workers wait for responses, if your server completely locks up for 5 seconds, `goperf` will patiently wait and stop sending new requests. This means your p99 latencies might look slightly better than reality during an outage. If you need to test traffic that hits your server at a constant, unforgiving rate (open-loop testing), we highly recommend checking out [Vegeta](https://github.com/tsenart/vegeta?tab=readme-ov-file).

## Example Output Explained

```text
$ goperf run https://httpbin.org/get -c 50 -d 30s
Running for 30s against https://httpbin.org/get with concurrency 50
  [2s]  98 reqs | 49.0/s
  [4s]  210 reqs | 52.5/s
  ...

Target:     https://httpbin.org/get
Duration:   30.0s
Requests:   1,523 total (1,520 succeeded, 3 failed)

Status code distribution:
  [200] 1520 responses
  [500] 3 responses

Latency:
  Fastest:  12.00ms   <- The quickest single request
  Slowest:  892.00ms  <- The worst outlier request
  Average:  45.00ms   <- Standard mean latency
  p50:      38.00ms   <- 50% of your users experienced 38ms or better (Median)
  p90:      89.00ms   <- 90% of your users experienced 89ms or better
  p99:      234.00ms  <- 99% of your users experienced 234ms or better

Response time histogram:
  12.000 [50]   |■■■■■■■■■■■■■■■■■■■■■
  100.000 [150] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  892.000 [3]   |■

Throughput: 50.7 requests/sec <- How much total work was accomplished
```

