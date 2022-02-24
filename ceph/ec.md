### 添加 EC 
```
it's the same way with do with rack failure domain when we have 4 racks and a minimum of 3 hosts per rack for EC 8+3 or EC 8+4

if you use 8+3 you need to lower min_size to 8 to have it work all the time in maintenance mode, if you use 8+4, you can still keep the default min_size of 9

rule ec_k8_m3_or_m4_ruleset_hdd {
        id <X>
        type erasure
        min_size 7
        max_size 14
        step take default class hdd
        step choose firstn 4 type host
        step chooseleaf indep 3 type osd
        step emit
}

once you created the rule, you create the profile such as : 
8+3 => ceph osd erasure-code-profile set ec_k8_m3_profile k=8 m=3 crush-device-class=hdd crush-failure-domain=osd
8+4 => ceph osd erasure-code-profile set ec_k8_m4_profile k=8 m=4 crush-device-class=hdd crush-failure-domain=osd

and the you create a pool with : 
8+3 => ceph osd pool create my_ec_pool 128 128 erasure ec_k8_m3_profile ec_k8_m3_or_m4_ruleset_hdd
8+4 => ceph osd pool create my_ec_pool 128 128 erasure ec_k8_m4_profile ec_k8_m3_or_m4_ruleset_hdd


```