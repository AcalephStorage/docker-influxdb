#!/usr/bin/python
import argparse
import whisper
import os
import time
import subprocess
from socket import socket


DEFAULT_HOST="127.0.0.1"
DEFAULT_PORT="2003"

now = int(time.time())

def search(pwd):
    whisper_files = []
    for path,directory,filenames in os.walk(pwd):
        for files in filenames:
            whisper_files.append(os.path.join(path,files))
    return whisper_files

def lame_whisper_read(whisper_file):
    linux_cmd = subprocess.Popen(["/usr/local/bin/whisper-fetch.py", "--from=0", whisper_file, ], stdout=subprocess.PIPE,)
    stdout = linux_cmd.communicate()[0]
    data = {}
    for line in stdout.split('\n'):
        try: time, value = line.split()[0], line.split()[1] 
        except:
            continue
        if value != 'None':
            data[time] = value
    return data

def send_data(metric, raw_data, host=DEFAULT_HOST, port=DEFAULT_PORT):
    data = []
    for time, value in raw_data.items():
        data.append("%s %s %s" % (metric, value, time))

    datastr = '\n'.join(data) + '\n'
    print datastr
    sock = socket()
    sock.connect((host,port))
    sock.sendall(datastr)
    sock.close()

def main():
    parser = argparse.ArgumentParser(description='whisper file to influxDB migration script')
    parser.add_argument('path', help='path to whispers')
    parser.add_argument('-host', default=DEFAULT_HOST, metavar="host", help="influxDB host")
    parser.add_argument('-port', default=DEFAULT_PORT, metavar="port", help="influxDB graphite plugin port")
    args = parser.parse_args()

    for whisper_file in search(os.path.join(args.path,'')):
        data = lame_whisper_read(whisper_file)
        metric = whisper_file.split('.')[0].split(args.path)[1].replace('/', '.')
        send_data(metric, data, args.host, int(args.port))

if __name__ == '__main__':
    main()
