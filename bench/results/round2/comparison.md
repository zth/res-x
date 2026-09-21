| Workload | Previous PR µs/op | New µs/op | Additional speedup |
|---|---:|---:|---:|
| html/text-safe-4k | 0.204 | 0.201 | 1.01× |
| html/text-escaped | 1.668 | 1.743 | 0.96× |
| html/attributes | 0.525 | 0.497 | 1.06× |
| html/styles | 0.122 | 0.118 | 1.03× |
| html/list-100 | 24.792 | 27.850 | 0.89× |
| html/list-100-utf8 | 46.455 | 46.275 | 1.00× |
| html/create-and-render-100 | 51.363 | 42.205 | 1.22× |
| html/components-100 | 8.806 | 7.070 | 1.25× |
| html/context-depth-20 | 1.791 | 1.806 | 0.99× |
| html/raw-4k | 0.001 | 0.001 | 1.00× |
| html/small-sync-async-api | 0.154 | 0.096 | 1.60× |
| html/single-promise | 0.529 | 0.271 | 1.95× |
| html/async-api-sync-tree | 25.441 | 24.953 | 1.02× |
| html/async-sparse | 57.576 | 45.637 | 1.26× |
| html/async-dense-100 | 28.952 | 29.358 | 0.99× |
| html/async-nested | 39.836 | 27.710 | 1.44× |
| context/als-run | 0.009 | 0.009 | 0.95× |
| context/als-read-100 | 0.239 | 0.240 | 1.00× |
| context/als-await | 0.116 | 0.118 | 0.98× |
| request/controller | 0.111 | 0.086 | 1.29× |
| request/minimal | 5.184 | 5.075 | 1.02× |
| request/page-100 | 61.919 | 60.161 | 1.03× |
| request/context-components-100 | 10.396 | 9.557 | 1.09× |
| request/head-title-body | 7.170 | 7.082 | 1.01× |
| request/route-hit-1000 | 4.600 | 4.216 | 1.09× |
| request/route-miss-1000 | 3.698 | 3.676 | 1.01× |
