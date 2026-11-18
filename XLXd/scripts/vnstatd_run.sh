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
## --sync: a new container has a new eth0 whose counters start at 0, and without it vnstatd takes the drop from
## the counters saved in the database for a 32-bit counter wrap - every re-create added a phantom 4 GiB+ each way
exec vnstatd -n --sync
