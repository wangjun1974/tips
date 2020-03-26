参见：

How to configure TCP BBR as the default congestion control algorithm?
- https://access.redhat.com/solutions/3713681

BBR: Congestion-Based Congestion Control
Measuring bottleneck bandwidth and round-trip propagation time
- https://queue.acm.org/detail.cfm?id=3022184

TCP BBR : Magic dust for network performance.
- https://medium.com/google-cloud/tcp-bbr-magic-dust-for-network-performance-57a5f1ccf437


检查 congestion，如果未启用bbr，net.ipv4.tcp_congestion_control应为cubic
```
sysctl -a | egrep -e congestion
net.ipv4.tcp_allowed_congestion_control = reno cubic
net.ipv4.tcp_available_congestion_control = reno cubic
net.ipv4.tcp_congestion_control = cubic
```

如果net.ipv4.tcp_congestion_control不是bbr，则调整为bbr
```
sysctl -w net.ipv4.tcp_congestion_control=bbr
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
```

查看调整情况
```
sysctl -a | egrep -e congestion
net.ipv4.tcp_allowed_congestion_control = reno cubic bbr
net.ipv4.tcp_available_congestion_control = reno cubic bbr
net.ipv4.tcp_congestion_control = bbr
```

假设通过ssh远程登陆系统，可以退出登陆并且重新ssh进入系统
```
ss -tin sport = :22
State            Recv-Q              Send-Q                            Local Address:Port                             Peer Address:Port                                                                                                                                                                   
ESTAB            0                   0                                   172.31.7.69:22                             119.254.120.68:43808             
         bbr wscale:7,7 rto:446 rtt:245.042/7.852 ato:40 mss:1348 pmtu:9001 rcvmss:1348 advmss:8949 cwnd:122 bytes_acked:97789 bytes_received:9669 segs_out:414 segs_in:555 data_segs_out:399 data_segs_in:187 bbr:(bw:1.8Mbps,mrtt:240.723,pacing_gain:2.88672,cwnd_gain:2.88672) send 5.4Mbps lastsnd:4044682 lastrcv:4044684 lastack:4044441 pacing_rate 5.4Mbps delivery_rate 1.8Mbps app_limited busy:40880ms retrans:0/17 rcv_rtt:243 rcv_space:26847 rcv_ssthresh:37927 minrtt:240.691
```