# Experf

  This is an example Elixir application, it performs a number of concurrent http requests to a url,
  the concurrency and number of requests per second can be configured.

```
$ mix deps.get
$ mix escript.build
$ ./experf --num-requests=10 --concurrency=2 --rps=2 --url=http://www.example.com

00:49:19.926 [info]  %{concurrency: 2, num_requests: 10, rps: 2, url: "http://localhost:5000"}
00:49:20.938 [info]  2/10 requests finished
00:49:21.939 [info]  4/10 requests finished
00:49:22.941 [info]  6/10 requests finished
00:49:23.943 [info]  8/10 requests finished
00:49:23.959 [info]  10 requests finished in 4.02522 secs
00:49:23.960 [info]  Average response time 14 (ms), stdev 10.61478777225433 (ms)
00:49:23.960 [info]  10 - Successful Requests
00:49:23.960 [info]  0 - Errors
```
