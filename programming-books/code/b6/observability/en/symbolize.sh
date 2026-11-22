$ flutter symbolize -i crash.txt -d build/symbols/app.linux-x64.symbols
crash: Null check operator used on a null value
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 31689, tid: 140066282179392, name io.flutter.ui
os: linux arch: x64 comp: no sim: no
build_id: '49da3cbf4c5e4c216b483b3b31889a38'
isolate_dso_base: 7f639c179000, vm_dso_base: 0
isolate_instructions: 7f639c23d000, vm_instructions: 0
Failed to symbolize stack trace:
 Cannot locate isolate instructions section in snapshot
