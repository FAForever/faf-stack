"Delete a user from FAF (GDPR deletion request)"
import argparse
import configparser
import contextlib
import logging
import subprocess

import pymysql
from pymysql.cursors import DictCursor


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mysql_config', type=argparse.FileType('r'),
                        help='path to mysql.cnf for snapshotted database',
                        default='config/faf-db/mysql.cnf')
    parser.add_argument('--database', help='FAF core database',
                        default='faf_lobby')

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--username', help='current username')
    group.add_argument('--email', help='current email')
    return parser.parse_args()


def setup_logging(options):
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
    except Exception:
        logging.exception("step failed")
        raise


def main(options):
    with logged_step("reading MySQL config"):
        config = configparser.ConfigParser()
        with options.mysql_config:
            config.read_file(options.mysql_config)
        kwargs = {k: config['client'][k] for k in ('user', 'password', 'host')}

    with logged_step("analyzing user"):
        conn = pymysql.Connection(**kwargs, database=options.database)

        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            if options.username:
                cursor.execute("SELECT * FROM login WHERE login = %s", (options.username))
            elif options.email:
                cursor.execute("SELECT * FROM login WHERE email = %s", (options.email))
            else:
                raise ValueError("Invalid options: no username, no email")

            user = cursor.fetchone()

            if user is None:
                print("No matching user found!")
                exit(1)

            user_id = user['id']

            print("User:\t\t", user['login'])
            print("Email:\t\t", user['email'])
            print("Last IP:\t", user['ip'])
            print("Last login:\t", user['last_login'])

            cursor.execute("SELECT count(*) AS games FROM game_player_stats WHERE playerId = %s", user_id)
            games = cursor.fetchone()['games']

            print("# of games:\t", games)

            cursor.execute("SELECT * FROM service_links WHERE user_id = %s", user_id)
            service_links = cursor.fetchall()

            for link in service_links:
                print("Link:\t\t", link['type'], ' @ ', link['service_id'])

            cursor.execute("SELECT count(*) as bans FROM ban WHERE player_id = %s", user_id)
            bans = cursor.fetchone()['bans']

            if bans > 0:
                print("!!! WARNING: Player has ban history (", bans, " entries) !!")

            cursor.execute("DELETE FROM login_log WHERE login_id = %s", user_id)
            cursor.execute("DELETE FROM name_history WHERE user_id = %s", user_id)
            cursor.execute("""
                UPDATE login 
                SET password = 'anonymized', 
                    login = concat('anonymized_', id), 
                    email = concat('anonymized_', id),
                    ip = null, 
                    steamid = null, 
                    gog_id = null, 
                    user_agent = null, 
                    last_login = null 
                where id = %s;
                """, user_id)

            if games == 0:
                print("Player has no games! Starting complete account wipe!")

                cursor.execute("DELETE FROM service_links WHERE user_id = %s and ownership = 0", user_id)
                cursor.execute("DELETE FROM leaderboard_rating WHERE login_id = %s", user_id)
                cursor.execute("DELETE FROM login WHERE id = %s", user_id)
            else:
                cursor.execute("UPDATE service_links sl SET user_id = null WHERE user_id = %s and ownership = 1",
                               user_id)

            while (input("Please confirm by typing CONFIRM: ") != 'CONFIRM'):
                pass

            conn.commit()

            print("!! IMPORTANT: Please delete user ", user['login'], " from wiki & forum manually!!")


if __name__ == '__main__':
    options = parse_arguments()
    setup_logging(options)
    main(options)
