# The same month, two ways to alert
$ node alerts.ts
rule                             fired   real   false
naive: >1% in 1 min                456    291     165
page: 14.4x for 1 h and 5 min        1      1       0 day 17 20:18
page: 6x for 6 h and 30 min          1      1       0 day 17 20:26
ticket: 3x for 1 d and 2 h           2      2       0 day 17 20:28, day 24 18:06
