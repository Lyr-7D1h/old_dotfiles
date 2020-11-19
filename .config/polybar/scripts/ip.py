#!/usr/bin/env python

from requests import get, ConnectionError

try:
    ip = get('https://ifconfig.me').text

    print(ip) 
except:
    print("disconnected")
    
