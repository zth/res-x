| Workload | Baseline µs/op | Candidate µs/op | Speedup |
|---|---:|---:|---:|
| html/text-safe-4k | 0.223 | 0.199 | 1.12× |
| html/text-escaped | 1.867 | 1.752 | 1.07× |
| html/attributes | 1.291 | 1.155 | 1.12× |
| html/styles | 0.403 | 0.135 | 2.99× |
| html/list-100 | 59.080 | 32.450 | 1.82× |
| html/list-100-utf8 | 65.797 | 50.256 | 1.31× |
| html/create-and-render-100 | 87.235 | 52.247 | 1.67× |
| html/components-100 | 23.100 | 10.870 | 2.13× |
| html/context-depth-20 | 4.303 | 3.455 | 1.25× |
| html/raw-4k | 0.080 | 0.030 | 2.66× |
| html/async-api-sync-tree | 67.027 | 32.895 | 2.04× |
| html/async-sparse | 157.896 | 63.236 | 2.50× |
| html/stream-async-tail | 94.427 | 61.662 | 1.53× |
| html/async-dense-100 | 51.861 | 33.294 | 1.56× |
| html/async-nested | 73.210 | 115.705 | 0.63× |
| html/stream-sync-tree | 68.351 | 105.533 | 0.65× |
| context/als-run | 0.014 | 0.013 | 1.11× |
| context/als-read-100 | 0.077 | 0.075 | 1.03× |
| context/als-await | 0.129 | 0.129 | 1.00× |
| request/controller | 0.188 | 0.184 | 1.02× |
| request/minimal | 5.314 | 5.505 | 0.97× |
| request/page-100 | 190.357 | 75.895 | 2.51× |
| request/context-components-100 | 24.129 | 14.087 | 1.71× |
| request/head-title-body | 11.962 | 9.074 | 1.32× |
| request/route-hit-1000 | 5.225 | 4.491 | 1.16× |
| request/route-miss-1000 | 3.848 | 3.710 | 1.04× |
