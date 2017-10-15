#!/usr/bin/env python3
# vim:set ts=4 sw=4 sts=4 expandtab:

from os.path import exists
from requests import codes, get
from subprocess import run, CalledProcessError
from sys import exit
import argparse

devices = {'angler':   { 'timestamp': 0, 'url': 'https://legacy.copperhead.co' },
           'bullhead': { 'timestamp': 0, 'url': 'https://legacy.copperhead.co' },
           'marlin':   { 'timestamp': 0, 'url': 'https://release.copperhead.co' },
           'sailfish': { 'timestamp': 0, 'url': 'https://release.copperhead.co' }
          }

def getReleases():
    """Return the list of release from Copperhead"""

    response = dict()
    for device in args.devices:
        url = "/".join([devices[device]['url'], device + '-stable'])
        response[device] = dict()
        r = get(url)
        if r.status_code == codes.ok:
            response[device]['raw'] = r.text
        else:
            print('There was a problem getting the release info: HTTP {}: {}'.format(r.status_code, r.text))
            exit(1)

    return response

def prepareFactoryData(releases):
    for device, data in releases.items():
        date, timestamp, build = releases[device]['raw'].strip().split(' ')
        releases[device]['factory_filename'] = "".join([device, '-factory-', date.strip(), '.tar.xz'])
        releases[device]['factory_signature_filename'] = "".join([releases[device]['factory_filename'], '.sig'])
        releases[device]['factory_url'] = "/".join([devices[device]['url'], releases[device]['factory_filename']])
        releases[device]['factory_signature_url'] = "".join([releases[device]['factory_url'], '.sig'])
    return releases

def filterDevices(releases):
    filtered = dict()
    for device in args.devices:
        filtered[device] = releases[device]
    return filtered

def downloadFactoryImage(releases):
    downloaded_image = False
    downloaded_signature = False

    for device, data in releases.items():
        if not exists(data['factory_filename'] + '.dat'):
            with open(data['factory_filename'] + '.dat', 'wt') as file:
                file.write(data['raw'])

        if not exists(data['factory_filename']):
            print("Found new factory image, downloading now:", data['factory_filename'])

            with open(data['factory_filename'], 'wb') as file:
                ota_file = get(data['factory_url'])
                file.write(ota_file.content)

            downloaded_image = True

        if not exists(data['factory_signature_filename']):
            print("Found new factory image signature, downloading now:", data['factory_signature_filename'])
            with open(data['factory_signature_filename'], 'wb') as file:
                ota_file = get(data['factory_signature_url'])
                file.write(ota_file.content)
            downloaded_signature = True

    if downloaded_image and downloaded_signature:
        validateDownloads(releases)

def validateDownloads(releases):
    for device, data in releases.items():
        if exists(data['factory_filename']) and exists(data['factory_signature_filename']):
            print('Validating', data['factory_filename'])
            try:
                run(['gpg', '--no-permission-warning', '--quiet', '--batch', data['factory_signature_filename']], check=True)
            except CalledProcessError:
                print('There was a problem validating the signature.')
                exit(1)

def main():
    releases = filterDevices( prepareFactoryData( getReleases()))
    downloadFactoryImage(releases)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Download the latest release for given device(s).')
    parser.add_argument('devices', metavar='device', type=str, nargs='+', help=", ".join(devices.keys()))
    args = parser.parse_args()

    main()
