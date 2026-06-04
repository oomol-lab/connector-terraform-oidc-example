#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  oidc-fingerprint.sh [--json] <issuer-url>

Print the SHA-1 fingerprint of the topmost certificate in the issuer TLS
certificate chain. Use --json when called from Terraform's external data source.
EOF
}

json=false

if [[ "${1:-}" == "--json" ]]; then
  json=true
  shift
fi

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 2
fi

url="$1"

host_port="$(
  URL="$url" awk '
    BEGIN {
      url = ENVIRON["URL"]
      sub(/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//, "", url)
      sub(/[\/?#].*$/, "", url)
      if (url == "") {
        exit 1
      }
      print url
    }
  '
)"

host="${host_port%%:*}"
port="${host_port##*:}"

if [[ -z "$host" ]]; then
  echo "failed to parse host from URL: $url" >&2
  exit 2
fi

if [[ "$port" == "$host_port" ]]; then
  port=443
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

certs="$tmpdir/certs.pem"
error_log="$tmpdir/openssl.err"

if ! openssl s_client \
  -showcerts \
  -servername "$host" \
  -connect "$host:$port" \
  </dev/null >"$certs" 2>"$error_log"; then
  echo "failed to fetch TLS certificates from $host:$port" >&2
  cat "$error_log" >&2
  exit 1
fi

awk '
  /-----BEGIN CERTIFICATE-----/ {
    cert += 1
    out = sprintf("%s/cert-%03d.pem", dir, cert)
  }
  out != "" {
    print > out
  }
  /-----END CERTIFICATE-----/ {
    out = ""
  }
' dir="$tmpdir" "$certs"

cert_count="$(find "$tmpdir" -name 'cert-*.pem' -type f | wc -l | tr -d ' ')"

if [[ "$cert_count" -eq 0 ]]; then
  echo "no TLS certificates returned by $host:$port" >&2
  exit 1
fi

leaf_subject="$(openssl x509 -in "$tmpdir/cert-001.pem" -noout -subject)"
leaf_issuer="$(openssl x509 -in "$tmpdir/cert-001.pem" -noout -issuer)"

if [[ "$cert_count" -eq 1 && "$leaf_subject" != "$leaf_issuer" ]]; then
  echo "server did not return a CA chain for $host:$port" >&2
  exit 1
fi

fingerprint="$(
  openssl x509 \
    -in "$(printf "%s/cert-%03d.pem" "$tmpdir" "$cert_count")" \
    -noout \
    -fingerprint \
    -sha1 |
    sed 's/^.*=//; s/://g; y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'
)"

if [[ "$json" == true ]]; then
  printf '{"fingerprint":"%s"}\n' "$fingerprint"
else
  printf '%s\n' "$fingerprint"
fi
