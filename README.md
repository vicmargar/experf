# Experf

  This is an example Elixir application, it performs a number of concurrent http requests to a url,
  the concurrency and number of requests per second can be configured.

    mix deps.get
    mix escript.build

```
./experf --num-requests=100 --concurrency=10 --rps=20 --url=http://localhost:8080
[num_requests: 100, concurrency: 10, rps: 20, url: "http://localhost:8080"]
20/100 requests finished
40/100 requests finished
60/100 requests finished
80/100 requests finished
100 requests finished in 4.010268 secs
Average response time 6 (ms)
```
