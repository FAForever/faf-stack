import argparse
import configparser
import contextlib
import functools
import pathlib
import re
import subprocess
import sys

import pymysql

# Based on https://docs.oracle.com/cd/E26505_01/html/E37384/gbcpt.html
SNAPSHOT_NAME_PATTERN = re.compile('[-a-zA-Z0-9_:.]+/[-a-zA-Z0-9_:./]+@[-a-zA-Z0-9_:.]+')

def zfs(args, timeout=10, stdout=subprocess.PIPE, **kwargs):
    return subprocess.run(["zfs"] + args, timeout=timeout, stdout=stdout, stderr=subprocess.PIPE, check=True, **kwargs)

def parse_arguments(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('mysql_config', help='path to mysql.cnf for snapshotted database', type=argparse.FileType('r'))
    parser.add_argument('snapshot_name', help='zfs dataset name for the snapshotted database data directory')
    parser.add_argument('send_file', help='filename for where zfs-send output should be written',
                        type=argparse.FileType('wb'))
    options = parser.parse_args(argv[1:])
    if not SNAPSHOT_NAME_PATTERN.match(options.snapshot_name):
        parser.error(f"{options.snapshot_name} doesn't look like a valid snapshot name")
    return options

@contextlib.contextmanager
def frozen_database(conn):
    with conn:
        with conn.cursor() as cursor:
            cursor.execute("BACKUP STAGE START;")
            cursor.execute("BACKUP STAGE BLOCK_COMMIT;")
            yield
            cursor.execute("BACKUP STAGE END;")

def main(options):
    config = configparser.ConfigParser()
    with options.mysql_config:
        config.read_file(options.mysql_config)
    kwargs = {k: config['client'][k] for k in ('user', 'password', 'host')}

    try:
        zfs(["destroy", options.snapshot_name])
    except subprocess.CalledProcessError as error:
        if b'could not find any snapshots to destroy' not in error.stderr:
            raise

    conn = pymysql.Connection(**kwargs)
    with frozen_database(conn):
        zfs(["snapshot", options.snapshot_name])

    send = subprocess.Popen(["zfs", "send", options.snapshot_name], stdout=subprocess.PIPE)
    zstd = subprocess.Popen(["zstd", "-10", "-T4"], stdout=options.send_file, stdin=send.stdout)
    send.wait()
    if send.returncode != 0:
        raise CalledProcessError(send.returncode, "zfs send")
    zstd.wait()


if __name__ == '__main__':
    main(parse_arguments(sys.argv))
