#!/usr/bin/env python
# -*- coding: utf-8 -*-
import re
import socket

text = raw_input('ASN: ')

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("whois.radb.net", 43))

if 'as' or 'AS' in text:
	s.send(('-i origin ' + text + "\r\n").encode())
else:
	s.send(('-i origin as' + text + "\r\n").encode())

response = b""
while True:
    data = s.recv(4096)
    response += data
    if not data:
        break
s.close()

for item in response.decode().split("\n"):
	if "route:" in item:
		print item.strip()
	if "route6:" in item:
		print item.strip()

quit()