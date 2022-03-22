# Source this file.

_check_gc_dir() {
  if [ -z "${GC_CORE_DIR+x}" ]; then
    >&2 echo "GC_CORE_DIR is not set. Are you in the Goodcover Core source directory?"
    return 1
  fi
  return 0
}

mysql-start() {
  _check_gc_dir && \
    mysqld \
    "--datadir=${GC_CORE_DIR}/datadir/mysql" \
    "--log-error=${GC_CORE_DIR}/datadir/mysql/goodness.err" \
    --pid-file=goodness.pid \
    "--socket=${GC_CORE_DIR}/datadir/mysql.sock" \
    > /dev/null 2>&1 &
}

mysql-stop() {
  _check_gc_dir && \
    mysqladmin shutdown "--socket=${GC_CORE_DIR}/datadir/mysql.sock"
}

cassandra-start() {
  _check_gc_dir && \
    MAX_HEAP_SIZE=4G \
    HEAP_NEWSIZE=800M \
    CASSANDRA_LOG_DIR="${GC_CORE_DIR}/datadir/cassandra/logs" \
    cassandra \
    -p "${GC_CORE_DIR}/datadir/cassandra/cassandra.pid" \
    "-Dcassandra.config=file://${HOME}/.config/goodcover/cassandra.yaml"
}
