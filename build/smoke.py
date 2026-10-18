#!/usr/bin/env python3
"""Exercise the built image's authentication, media processing, and persisted restart."""
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid

image = sys.argv[1]
name = 'restreamer-smoke-' + uuid.uuid4().hex[:12]
volume = name + '-config'
base = ''


def docker(*args):
    return subprocess.check_output(['docker', *args], text=True).strip()


def request(path, token=None, data=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(base + path, headers=headers,
                                 data=None if data is None else json.dumps(data).encode())
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            status, body = response.status, response.read()
    except urllib.error.HTTPError as error:
        status, body = error.code, error.read()
    assert status == expected, (path, status, body.decode())
    return json.loads(body) if body else None


def ready():
    for _ in range(60):
        try:
            request('/api/v3/process', expected=401)
            return
        except (OSError, AssertionError):
            time.sleep(1)
    raise RuntimeError('Container did not become ready')


def login():
    return request('/api/login', data={'username': 'smoke', 'password': 'smoke-test-password'})


try:
    docker('volume', 'create', volume)
    docker('run', '-d', '--name', name, '-p', '127.0.0.1::8080',
           '-v', volume + ':/core/config',
           '-e', 'CORE_API_AUTH_ENABLE=true', '-e', 'CORE_API_AUTH_USERNAME=smoke',
           '-e', 'CORE_API_AUTH_PASSWORD=smoke-test-password', image)
    port = docker('port', name, '8080/tcp').rsplit(':', 1)[1]
    base = 'http://127.0.0.1:' + port
    ready()
    tokens = login()
    access, refresh = tokens['access_token'], tokens['refresh_token']
    request('/api/v3/process', token='invalid', expected=401)
    request('/api/v3/process', token=refresh, expected=401)
    request('/api/login/refresh', token=refresh)
    skills = request('/api/v3/skills', token=access)
    assert skills['ffmpeg']['version'].startswith('6.1.6'), skills['ffmpeg']
    with urllib.request.urlopen(base + '/ui/') as response:
        html = response.read().decode()
    asset = re.search(r'src="([^\"]+\.js)"', html).group(1)
    with urllib.request.urlopen(base + '/ui/' + asset.removeprefix('./')) as response:
        assert response.status == 200
    config = {
        'id': 'smoke', 'type': 'ffmpeg', 'autostart': True,
        'options': ['-y'],
        'input': [
            {'address': 'testsrc=size=160x90:rate=10', 'options': ['-re', '-f', 'lavfi']},
            {'address': 'sine=frequency=440:sample_rate=44100', 'options': ['-re', '-f', 'lavfi']},
        ],
        'output': [{'address': '/core/data/smoke.m3u8',
                    'options': ['-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'ultrafast',
                                '-c:a', 'aac', '-b:a', '64k', '-g', '10', '-f', 'hls',
                                '-hls_time', '1', '-hls_list_size', '3']}],
    }
    request('/api/v3/process', token=access, data=config)
    for _ in range(30):
        try:
            playlist = docker('exec', name, 'cat', '/core/data/smoke.m3u8')
            if '#EXTINF:' in playlist:
                break
        except subprocess.CalledProcessError:
            pass
        time.sleep(1)
    else:
        raise RuntimeError('HLS output was not produced')
    state = request('/api/v3/process/smoke/state', token=access)
    assert state['exec'] == 'running', state
    assert state['progress']['frame'] > 0, state
    media = json.loads(docker('exec', name, 'ffprobe', '-v', 'error',
                              '-show_entries', 'stream=codec_name,width,height',
                              '-of', 'json', '/core/data/smoke.m3u8'))
    assert any(s.get('codec_name') == 'h264' and s.get('width') == 160 and s.get('height') == 90
               for s in media['streams']), media
    assert any(s.get('codec_name') == 'aac' for s in media['streams']), media
    docker('restart', name)
    port = docker('port', name, '8080/tcp').rsplit(':', 1)[1]
    base = 'http://127.0.0.1:' + port
    ready()
    access = login()['access_token']
    persisted = request('/api/v3/process/smoke/config', token=access)
    assert persisted['input'][0]['address'] == config['input'][0]['address'], persisted
    for _ in range(30):
        restarted = request('/api/v3/process/smoke/state', token=access)
        if restarted['exec'] == 'running' and restarted['progress']['frame'] > 0:
            break
        time.sleep(1)
    else:
        raise RuntimeError('Saved stream did not resume encoding after restart')
    print('PASS: UI assets, JWT access/refresh separation, FFmpeg 6.1.6 H.264/AAC HLS encoding, progress, saved-stream restart')
except Exception:
    subprocess.run(['docker', 'logs', name], check=False)
    raise
finally:
    subprocess.run(['docker', 'rm', '-f', '-v', name], check=False, stdout=subprocess.DEVNULL)
    subprocess.run(['docker', 'volume', 'rm', volume], check=False, stdout=subprocess.DEVNULL)
