#!/command/with-contenv sh
## vnstatd collects traffic for the dashboard's Traffic statistics page - only when TRAFFIC_PAGE is on
. /etc/s6-overlay/scripts/dashboard-env.sh

if [ "$(env_bool "${TRAFFIC_PAGE:-}" false TRAFFIC_PAGE 2> /dev/null)" != "true" ]; then
  # nothing to collect - stay up but idle so s6 doesn't restart us
  exec /command/s6-pause
fi

## first start on an empty database adds the container's interfaces (eth0 carries all reflector traffic)
## mount /var/lib/vnstat to keep the history across container re-creates
mkdir -p /var/lib/vnstat
exec vnstatd -n
