import argparse
import configparser
import contextlib
import functools
import logging
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
    parser.add_argument('--log_file')
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

def setup_logging(options):
    if options.log_file:
        logging.basicConfig(filename=options.log_file)
    elif sys.stderr.isatty():
        logging.basicConfig(level=logging.INFO)
    logging.basicConfig()

@contextlib.contextmanager
def logged_step(message):
    logging.info(message)
    try:
        yield
    except KeyboardInterrupt:
        logging.warning("interrupted!")
        raise SystemExit(1)
    except subprocess.CalledProcessError as error:
        logging.error(f"{error.cmd} failed ({error.returncode}); stderr: {error.stderr}")
        raise SystemExit(1)
    except Exception as error:
        logging.exception("step failed")
        raise

def main(options):
    with logged_step("reading MySQL config"):
        config = configparser.ConfigParser()
        with options.mysql_config:
            config.read_file(options.mysql_config)
        kwargs = {k: config['client'][k] for k in ('user', 'password', 'host')}

    with logged_step("destroying previous snapshot, if any"):
        try:
            zfs(["destroy", options.snapshot_name])
        except subprocess.CalledProcessError as error:
            if b'could not find any snapshots to destroy' not in error.stderr:
                raise
    
    with logged_step("connecting to database"):
        conn = pymysql.Connection(**kwargs)

    with logged_step("freezing database and taking snapshot"):
        with frozen_database(conn):
            zfs(["snapshot", options.snapshot_name])

    with logged_step("dumping compressed zfs send"):
        send = subprocess.Popen(["zfs", "send", options.snapshot_name], stdout=subprocess.PIPE)
        zstd = subprocess.Popen(["zstd", "-10", "-T4"], stdout=options.send_file, stdin=send.stdout)
        send.wait()
        if send.returncode != 0:
            raise subprocess.CalledProcessError(send.returncode, "zfs send")
        zstd.wait()

if __name__ == '__main__':
    options = parse_arguments(sys.argv)
    setup_logging(options)
    main(options)
