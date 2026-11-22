$ build/linux/x64/release/bundle/bit_app > crash.txt 2>/dev/null; cat crash.txt
crash: Null check operator used on a null value
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 31689, tid: 140066282179392, name io.flutter.ui
os: linux arch: x64 comp: no sim: no
build_id: '49da3cbf4c5e4c216b483b3b31889a38'
isolate_dso_base: 7f639c179000, vm_dso_base: 0
isolate_instructions: 7f639c23d000, vm_instructions: 0
    #00 abs 00007f639c3b8917 virt 000000000023f917 _kDartSnapshotText+0x17b917
    #01 abs 00007f639c3b87da virt 000000000023f7da _kDartSnapshotText+0x17b7da
    #02 abs 00007f639c3b879d virt 000000000023f79d _kDartSnapshotText+0x17b79d
    #03 abs 00007f639c2595c2 virt 00000000000e05c2 _kDartSnapshotText+0x1c5c2
    #04 abs 00007f639c3be44a virt 000000000024544a _kDartSnapshotText+0x18144a
    #05 abs 00007f639c2581a5 virt 00000000000df1a5 _kDartSnapshotText+0x1b1a5
    #06 abs 00007f639c25812e virt 00000000000df12e _kDartSnapshotText+0x1b12e
    #07 abs 00007f639c3e5adc virt 000000000026cadc _kDartSnapshotText+0x1a8adc
    #08 abs 00007f639c3ba5cf virt 00000000002415cf _kDartSnapshotText+0x17d5cf
