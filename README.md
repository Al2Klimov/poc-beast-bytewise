## About

The shipped [Dockerfile](./Dockerfile) builds and runs
a [Boost.Beast usage example] for demonstrating a limitation of it.

### Build

```bash
docker build -t poc-beast-bytewise .
```

### Run

```bash
docker run -itp 8443:443 poc-beast-bytewise
```

### Observing the limitation

```bash
perl -e 'sleep 2; for (;;) { for my $c (split("", "GET /v1/status HTTP/1.1\r\nAuthorization: Basic cm9vdDowN2U4OWM2YmY3ZjJkOTQ3\r\nContent-Length: 0\r\n\r\n")) { print STDERR $c; print $c; $| = 1; select(undef, undef, undef, 0.01); } }; sleep 3600' |openssl s_client -connect 127.0.0.1:8443
```

```bash
perl -e 'sleep 2; for (;;) { for my $c (split("", "GET /v1/status HTTP/1.1\r\nAuthorization: Basic AAAA\r\nContent-Length: 0\r\n\r\n")) { print STDERR $c; print $c; $| = 1; select(undef, undef, undef, 0.01); } }; sleep 3600' |openssl s_client -connect 127.0.0.1:8443
```

The first command connects to the example app
and sends an HTTP request byte-by-byte (100 bytes per second).

The app is expected to return a 404-response,
but closes the connection unexpectedly instead.
With the second command (different credentials) this doesn't happen.

[Boost.Beast usage example]: https://www.boost.org/doc/libs/1_69_0/libs/beast/example/http/server/coro-ssl/http_server_coro_ssl.cpp
