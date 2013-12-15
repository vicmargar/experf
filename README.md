# Experf

    mix deps.get
    mix escriptize

```
 ./experf --n=100 -c=10 -rps=20 -u=http://localhost:8080
[num_requests: 100, concurrency: 10, rps: 20, url: "http://localhost:8080"]
20/100 requests finished
40/100 requests finished
60/100 requests finished
80/100 requests finished
100 requests finished in 4.012047 secs
Average response time 6 (ms)
```
