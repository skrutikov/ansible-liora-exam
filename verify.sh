#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
printf '=== Services ===\n'
systemctl is-active nginx mysql php8.3-fpm
printf '\n=== Nginx syntax ===\n'
sudo nginx -t
printf '\n=== MySQL connection ===\n'
MYSQL_PWD="$(cat .secrets/db_password)" mysql --protocol=socket --user=wordpress --database=wordpress -N -e 'SELECT 1;'
printf '\n=== WordPress + WooCommerce ===\n'
if sudo -u www-data wp core is-installed --path=/var/www/wordpress; then
  echo 'OK: WordPress is installed'
else
  echo 'FAIL: WordPress not initialized' >&2
  exit 1
fi
if sudo -u www-data wp plugin is-active woocommerce --path=/var/www/wordpress; then
  echo 'OK: WooCommerce is active'
else
  echo 'FAIL: WooCommerce is not active' >&2
  exit 1
fi
sudo -u www-data wp eval 'foreach (["shop","cart","checkout","myaccount"] as $p) { if (wc_get_page_id($p) <= 0) { fwrite(STDERR, "Missing WooCommerce page: ".$p."\\n"); exit(1); } } echo "OK: Shop, cart, checkout and account pages configured\\n";' --path=/var/www/wordpress
permalink="$(sudo -u www-data wp option get permalink_structure --path=/var/www/wordpress)"
if [[ -z "$permalink" ]]; then
  echo 'FAIL: Plain permalinks; /shop/ will not resolve correctly' >&2
  exit 1
fi
echo "OK: Permalink structure = $permalink"
product_id="$(sudo -u www-data wp eval 'echo wc_get_product_id_by_sku("liora-demo-product");' --path=/var/www/wordpress)"
if [[ -z "$product_id" || "$product_id" == 0 ]]; then
  echo 'FAIL: Demonstration product missing' >&2
  exit 1
fi
echo "OK: Demonstration product ID = $product_id"
printf '\n=== HTTP ===\n'
code="$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' http://127.0.0.1/)"
echo "HTTP status: $code"
case "$code" in 2*|3*) ;; *) exit 1;; esac
