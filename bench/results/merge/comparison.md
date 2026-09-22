| Workload | Main µs/op | Final PR µs/op | Speedup |
|---|---:|---:|---:|
| html/text-safe-4k | 0.224 | 0.196 | 1.15× |
| html/text-escaped | 1.900 | 1.855 | 1.02× |
| html/attributes | 0.549 | 0.546 | 1.01× |
| html/styles | 0.358 | 0.119 | 3.01× |
| html/list-100 | 52.883 | 25.828 | 2.05× |
| html/list-100-utf8 | 51.578 | 44.355 | 1.16× |
| html/create-and-render-100 | 69.073 | 41.940 | 1.65× |
| html/components-100 | 15.205 | 7.775 | 1.96× |
| html/context-depth-20 | 2.078 | 1.894 | 1.10× |
| html/raw-4k | 0.020 | 0.001 | 14.21× |
| html/small-sync-async-api | 0.287 | 0.098 | 2.92× |
| html/single-promise | 0.520 | 0.277 | 1.88× |
| html/async-api-sync-tree | 54.583 | 26.852 | 2.03× |
| html/async-sparse | 140.428 | 43.865 | 3.20× |
| html/async-dense-100 | 41.748 | 26.078 | 1.60× |
| html/async-nested | 56.136 | 25.653 | 2.19× |
| context/als-run | 0.009 | 0.010 | 0.88× |
| context/als-read-100 | 0.230 | 0.251 | 0.92× |
| context/als-await | 0.121 | 0.126 | 0.96× |
| request/controller | 0.099 | 0.086 | 1.14× |
| request/minimal | 5.062 | 4.770 | 1.06× |
| request/page-100 | 82.424 | 58.079 | 1.42× |
| request/context-components-100 | 11.188 | 10.192 | 1.10× |
| request/head-title-body | 8.179 | 6.834 | 1.20× |
| request/route-hit-1000 | 4.084 | 3.539 | 1.15× |
| request/route-miss-1000 | 3.561 | 3.240 | 1.10× |
