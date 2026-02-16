curl -X PUT \
	"https://api.cloudflare.com/client/v4/zones/2408da51d3c920d97d0fb0c722475044/rulesets/phases/http_ratelimit/entrypoint" -H "Authorization: Bearer $CF_AUTH_TOKEN" -d '{"rules": [
        {
            "description": "Avoid-Message-Login",
            "expression": "(http.request.uri.path wildcard r\"/api\") or (http.request.uri.path wildcard r\"/login\")",
            "ratelimit": {
                "characteristics": [
                    "ip.src"
                ],
                "requests_to_origin": false,
                "requests_per_period": 10,
                "period": 10,
                "mitigation_timeout": 10,
                "rate_exceeds": "request_base"
            },
            "customCounter": false,
            "action": "block"
        }
    ]
}'