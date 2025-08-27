#!/usr/bin/env bash
DOMAINS_FILE="$1"
ANSWER_IP="$2"

if [[ -z "$DOMAINS_FILE" || -z "$ANSWER_IP" ]]; then
  echo "Usage: $0 domains.txt <answer_ip>"
  exit 1
fi

declare -a DOMAINS_ORDER
declare -A SEEN
declare -A WILDCARDS

# Считаем все wildcard
while IFS= read -r domain; do
  [[ -z "$domain" ]] && continue
  DOMAINS_ORDER+=("$domain")
  if [[ "$domain" =~ ^\*\.(.+)$ ]]; then
    WILDCARDS["${BASH_REMATCH[1]}"]=1
  fi
done < "$DOMAINS_FILE"

# --- NGINX map ---
echo "### --- NGINX map entries ---"
for domain in "${DOMAINS_ORDER[@]}"; do
  [[ -z "$domain" ]] && continue
  # если обычный домен и ещё не выводили
  if [[ ! "$domain" =~ ^\*\.(.+)$ ]]; then
    [[ -n "${SEEN[$domain]}" ]] && continue
    SEEN["$domain"]=1
    echo "    \"~^${domain}\$\"             \$ssl_preread_server_name:443;"
    # если для этого домена есть wildcard — добавить wildcard правило
    if [[ -n "${WILDCARDS[$domain]}" ]]; then
      echo "    \"~^.*\\.${domain}\$\"         \$ssl_preread_server_name:443;"
    fi
  else
    base="${BASH_REMATCH[1]}"
    # wildcard правило
    [[ -n "${SEEN[$base]}" ]] && continue
    SEEN["$base"]=1
    echo "    \"~^${base}\$\"             \$ssl_preread_server_name:443;"
    echo "    \"~^.*\\.${base}\$\"         \$ssl_preread_server_name:443;"
  fi
done

# --- AdGuard rewrites ---
echo
echo "### --- AdGuard rewrites ---"
echo "  rewrites:"
for domain in "${DOMAINS_ORDER[@]}"; do
  [[ -z "$domain" ]] && continue
  echo "    - domain: \"$domain\""
  echo "      answer: $ANSWER_IP"
done