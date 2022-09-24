export PAGER=less

# exec into a quick exit script that shuts down s6 immediately and exits docker
function qb { exec docker-s6-quick-exit; }
