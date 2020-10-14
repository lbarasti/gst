# gst

TODO: Write a description here

## Installation

TODO: Write installation instructions here

## Usage

TODO: Write usage instructions here

## Development
To run Prometheus locally:
```
docker run --rm --name prometheus --network host -d -v /home/lbarasti/crystal/prometheus.yml:/etc/prometheus/prometheus.yml -p 127.0.0.1:9090:9090 prom/prometheus --config.file=/etc/prometheus/prometheus.yml
```

## Crystal references
[Process](https://crystal-lang.org/api/0.30.1/Process.html#pid:LibC::PidT-class-method)
[File](https://crystal-lang.org/api/0.30.1/File.html)
[HTTP FormData](https://crystal-lang.org/api/0.30.0/HTTP/FormData.html)
[MIME types](https://crystal-lang.org/api/0.27.1/MIME.html#DEFAULT_TYPES)
[Kemal](https://github.com/kemalcr/kemal/blob/v0.23.0/src/kemal/config.cr) [custom](https://github.com/kemalcr/kemal/blob/master/src/kemal/helpers/helpers.cr#L17) [handlers](https://github.com/kemalcr/kemal/blob/dcffd7b3f9c89a0847df95319db00912fb194595/spec/exception_handler_spec.cr)

## Ghostscript documentation
https://www.ghostscript.com/doc/current/VectorDevices.htm

## WebSocket
On writing [websocket servers](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers)
[Client-side](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket) websockets

## Vue.js
[Class and style bindings](https://vuejs.org/v2/guide/class-and-style.html)
[Form validation](https://vuejs.org/v2/cookbook/form-validation.html)
[Event handling](https://vuejs.org/v2/guide/events.html)

## Other references
[multipart/form-data](https://www.microfocus.com/documentation/idol/IDOL_12_0/MediaServer/Guides/html/English/Content/Shared_Admin/_ADM_POST_requests.htm)
[Async form submission](https://pqina.nl/blog/async-form-posts-with-a-couple-lines-of-vanilla-javascript/)
[curl cheatsheet](https://jvns.ca/images/curl.jpeg)

## Contributing

1. Fork it (<https://github.com/your-github-user/gst/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [lbarasti](https://github.com/lbarasti) - creator and maintainer
