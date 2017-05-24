#!/usr/bin/env python3
# vim:set ts=4 sw=4 sts=4 expandtab:

from json import loads
from requests import get
from os.path import exists
from subprocess import run, CalledProcessError
import argparse

latest = { 'angler': { 'timestamp': 0 },
           'bullhead': { 'timestamp': 0 },
           'flounder': { 'timestamp': 0 }
         }

def getReleases():
    """Return the list of release from Copperhead"""
    response = get('https://update.copperhead.co/releases.json')
    return loads(response.text)

def filterByLatest(releases):
    """Iterate the known devices as listed in the latest dict() at the top of
    this file and only return the latest for each device"""
    for release in releases['result']:
        for k, v in release.items():
            for device, data in latest.items():
                if k == 'filename' and v.startswith(device):
                    if int(latest[device]['timestamp']) < int(release['timestamp']):
                        latest[device] = release
    return latest

def prepareFactoryData(releases):
    for device, data in releases.items():
        releases[device]['factory_url'] = releases[device]['url'].replace('ota_update', 'factory').replace('zip', 'tar.xz')
        releases[device]['factory_signature_url'] = "".join([releases[device]['factory_url'], '.sig'])
        releases[device]['factory_filename'] = releases[device]['filename'].replace('ota_update', 'factory').replace('zip', 'tar.xz')
        releases[device]['factory_signature_filename'] = "".join([releases[device]['factory_filename'], '.sig'])
    return releases

def filterDevices(releases):
    filtered = dict()
    for device in args.devices:
        filtered[device] = releases[device]
    return filtered

def downloadFactoryImage(releases):
    for device, data in releases.items():
        if not exists(data['factory_filename']):
            print("Found new factory image, downloading now:", data['factory_filename'])

            with open(data['factory_filename'], 'wb') as file:
                ota_file = get(data['factory_url'])
                file.write(ota_file.content)

        if not exists(data['factory_signature_filename']):
            print("Found new factory image signature, downloading now:", data['factory_signature_filename'])
            with open(data['factory_signature_filename'], 'wb') as file:
                ota_file = get(data['factory_signature_url'])
                file.write(ota_file.content)

def validateDownloads(releases):
    for device, data in releases.items():
        if exists(data['factory_filename']) and exists(data['factory_signature_filename']):
            print('Validating', data['factory_filename'])
            try:
                run(['gpg', data['factory_signature_filename']], check=True)
            except CalledProcessError:
                print('There was a problem validating the signature.')

def main():
    releases = filterDevices( prepareFactoryData( filterByLatest( getReleases())))
    downloadFactoryImage(releases)
    validateDownloads(releases)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Download the latest release for given device(s).')
    parser.add_argument('devices', metavar='device', type=str, nargs='+', help=", ".join(latest.keys()))
    args = parser.parse_args()

    main()
