#!/usr/bin/env python
# coding=utf-8

import os
from PIL import Image

# server
from flask import Flask, render_template, jsonify, send_from_directory

#geolocation
from urllib2 import urlopen
from urllib import unquote_plus, FancyURLopener
import geoip2.database

# ================================================================================================ SETUP
__location__ = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))

__config__ = os.path.join(__location__, "config" )
__geodb__ = os.path.join(__location__, "geo", "GeoLite2-Country.mmdb")
__flags__ = os.path.join(__location__, "flags" )

if not os.path.isdir(__flags__):
	os.makedirs(__flags__)

class Firefox(FancyURLopener):
	version = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; it; rv:1.8.1.11) Gecko/20071127 Firefox/2.0.0.11'

firefox = Firefox()

# ================================================================================================ Flask

app = Flask(__name__, template_folder=__location__)
app.url_map.strict_slashes = False
app.jinja_env.trim_blocks = True
 
# ================================================================================================ Middleware
def service(action):
	os.system("sudo systemctl %s openvpn"%action)
	
def _restart():
	service("restart")

def _off():
	service("stop")
	os.system("sudo unlink /etc/openvpn/default.conf")

def _change(_location):
	location = os.path.join(__config__, "%s.conf"%_location) 
	if os.path.isfile(location):
 		os.system("sudo ln -sf '%s' /etc/openvpn/default.conf" % location )
		service("restart")
		return True

def _current():	
	location = os.path.splitext(os.path.basename(os.path.realpath("/etc/openvpn/default.conf")))[0]
	return location

def _country():
	reader = geoip2.database.Reader(__geodb__)
	return reader.country( firefox.open("https://api.ipify.org/").read() ).country
	
def _all():
	files = os.listdir(__config__)
	files.sort()
	files = sorted(files, key=lambda s: s.lower())
	return  [os.path.splitext(x)[0] for x in files]

# ================================================================================================ UI
@app.route('/')
def html():
	return render_template( "vpn.jinja2", locations = _all(), current = _current(), country = _country().name )

# ================================================================================================ API
@app.route('/all')
def all():
	current = _current()
	result = []
	for location in  _all():
		result.append( tuple((location , location == current)) )
	print(result)
	return  jsonify(result)

@app.route('/restart')
def restart():
	_restart()	
	return  "OK"

@app.route('/set/<location>/')
def unregister(location):
	if location == "off":
		_off()
		return "OFF"
	
	if _change(unquote_plus(location)):
		return "OK"
		
	return "UNKNOWN" 
	
@app.route('/country/')
def country():
	return _country().iso_code.lower()

# ================================================================================================ STATIC	
@app.route('/flag/')
def flag():
	country = _country().iso_code.lower()
	
	flag = os.path.join(__flags__, "%s.png"%country)
	if not os.path.isfile(flag):		
		firefox.retrieve("http://flagpedia.net/data/flags/ultra/%s.png"%country, os.path.join(__flags__, "__%s.png"%country))
		# Flag : 2560 x 1347
		# Inset Banner: 1740 x 560
		
		image = Image.open( os.path.join(__flags__, "__%s.png"%country) )
		w, h = image.size
		
		img_new = Image.new('RGBA', (1740, 1740))		
		img_resize = image.resize((2560 / (h/560) , 560))		
		
		img_new.paste(img_resize, tuple(map(lambda x:(x[0]-x[1])/2, zip(img_new.size, img_resize.size))))
		
		img_new.save(flag, "PNG")
	
		os.remove(os.path.join(__flags__, "__%s.png"%country))
		
	return send_from_directory(__flags__, "%s.png"%country)
	
	
# ================================================================================================ ERROR
@app.errorhandler(404)
def page_not_found(e):
	return "NOT FOUND", 404

@app.after_request
def add_header(r):
	r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
	r.headers["Pragma"] = "no-cache"
	r.headers["Expires"] = "0"
	r.headers['Cache-Control'] = 'public, max-age=0'
	return r

# ================================================================================================
# =================================     ENTRY POINT      =========================================
# ================================================================================================
if __name__=='__main__':
	app.run(host='192.168.0.60', port=80, debug=False, threaded=True)

