# TODO: get rid of this function as it is very hacky
get_ipv4() {
  REGEX="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
  ifconfig | grep enp -A 5 | grep -oP --color=none "${REGEX}" | awk 'NR == 1'
}