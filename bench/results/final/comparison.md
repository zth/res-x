| Workload | Baseline µs/op | Candidate µs/op | Speedup |
|---|---:|---:|---:|
| html/text-safe-4k | 0.222 | 0.199 | 1.12× |
| html/text-escaped | 1.805 | 1.653 | 1.09× |
| html/attributes | 1.280 | 1.169 | 1.09× |
| html/styles | 0.415 | 0.151 | 2.75× |
| html/list-100 | 64.193 | 30.017 | 2.14× |
| html/list-100-utf8 | 75.697 | 52.514 | 1.44× |
| html/create-and-render-100 | 84.618 | 50.746 | 1.67× |
| html/components-100 | 22.981 | 12.665 | 1.81× |
| html/context-depth-20 | 5.201 | 3.337 | 1.56× |
| html/raw-4k | 0.048 | 0.035 | 1.37× |
| html/async-api-sync-tree | 67.221 | 37.527 | 1.79× |
| html/async-sparse | 154.399 | 64.929 | 2.38× |
| html/stream-async-tail | 84.344 | 67.945 | 1.24× |
| html/async-dense-100 | 55.886 | 37.234 | 1.50× |
| html/async-nested | 75.396 | 50.984 | 1.48× |
| html/stream-sync-tree | 74.261 | 32.750 | 2.27× |
| context/als-run | 0.012 | 0.013 | 0.94× |
| context/als-read-100 | 0.074 | 0.075 | 1.00× |
| context/als-await | 0.132 | 0.126 | 1.05× |
| request/controller | 0.178 | 0.178 | 1.00× |
| request/minimal | 5.272 | 5.714 | 0.92× |
| request/page-100 | 191.210 | 72.595 | 2.63× |
| request/context-components-100 | 20.846 | 14.649 | 1.42× |
| request/head-title-body | 10.015 | 10.484 | 0.96× |
| request/route-hit-1000 | 5.069 | 4.255 | 1.19× |
| request/route-miss-1000 | 3.925 | 3.607 | 1.09× |
