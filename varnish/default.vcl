vcl 4.0;

backend default {
    .host = "${VARNISH_BACKEND_HOST}";
    .port = "${VARNISH_BACKEND_PORT}";
}

sub vcl_recv {

    if (req.method == "POST" && !req.http.Content-Length) {
        return (synth(411, "Content-Length required"));
    }

    # Require that the content be less than 8000 characters
    if (req.method == "POST" && !req.http.Content-Length ~ "^[1-7]?[0-9]{1,3}$") {
        return (synth(413, "Request content too large (>8000)"));
    }

}

sub vcl_backend_response {
    if (bereq.method == "GET") {
        set beresp.ttl = 60m;
    }

    if (beresp.status != 200) {
        set beresp.ttl = 0s;
    }

    set beresp.do_gzip = true;
}
