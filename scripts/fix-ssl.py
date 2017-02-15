import os,sys
import subprocess
import json


def _decode_list(data):
    rv = []
    for item in data:
        if isinstance(item, unicode):
            item = item.encode('utf-8')
        elif isinstance(item, list):
            item = _decode_list(item)
        elif isinstance(item, dict):
            item = _decode_dict(item)
        rv.append(item)
    return rv

def _decode_dict(data):
    rv = {}
    for key, value in data.iteritems():
        if isinstance(key, unicode):
            key = key.encode('utf-8')
        if isinstance(value, unicode):
            value = value.encode('utf-8')
        elif isinstance(value, list):
            value = _decode_list(value)
        elif isinstance(value, dict):
            value = _decode_dict(value)
        rv[key] = value
    return rv

def readjson(datafile):
    with open(datafile,'r') as data_file:
        try:
            data = json.load(data_file,object_hook=_decode_dict)
        except ValueError, e:
            data={}
    return data


def get_ssl_domains_local():
    with open('/etc/ssldomains') as sfile:
        lines=sfile.read().splitlines()
    ssldom={}
    for line in lines:
        x=line.split(":")
        domain=x[0]
        ip=x[1].strip()
        ssldom[domain] =[domain,ip]
    return ssldom

def get_vhost_data():
    userdata_file="/etc/userdatadomains.json"
    if os.path.exists(userdata_file):
        userdata_json=readjson(userdata_file)
        ssldomains=get_ssl_domains_local()
        userdata={}
        for domain in userdata_json:
            domainuser=userdata_json[domain][0].strip()
            dopmaintype=userdata_json[domain][2].strip()
            domainreal=userdata_json[domain][3].strip()
            domaindocroot=userdata_json[domain][4].strip()
            domainip=userdata_json[domain][5].split(':')[0].strip()
            #print domain,domainuser,dopmaintype,domainreal,domaindocroot,domainip
            userdata[domain]=[domain,domainuser,dopmaintype,domainreal,domaindocroot,domainip]
    else:
    	userdata={}
    return userdata

def get_user_home(cpuser):
    with open('/etc/passwd', 'r') as passwd:
        lines=passwd.read().splitlines()
    for line in lines:
        l=line.split(":")
        if l[0] == cpuser:
            home=l[5]
            return home


def get_vhost_data_from_file():
    userdata_file="/etc/userdatadomains"
    if os.path.exists(userdata_file):
        userdata={}
        with open(userdata_file, 'r') as ufile:
            lines=ufile.read().splitlines()
        for line in lines:
            domd=line.split(' ')
            doms=domd[0].split(':')
            domain=doms[0]
            ds=domd[1].split('=')
            domainuser=ds[0]
            domaintype=ds[4]
            domainreal=ds[6]
            domaindocroot=ds[8]
            domainip=ds[10].split(':')[0].strip()
            userdata[domain]=[domain,domainuser,domaintype,domainreal,domaindocroot,domainip]
    else:
        userdata={}
    return userdata


def get_ssl_domains():
    with open('/etc/ssldomains') as sfile:
        lines=sfile.read().splitlines()
    ssldom={}
    for line in lines:
        x=line.split(":")
        domain=x[0]
        ip=x[1].strip()
        ssldom[domain] =[domain,ip]
    alluserdata=get_vhost_data()
    alluserdata.update(get_vhost_data_from_file())
    for domain in alluserdata:
        if alluserdata[domain][2] == "addon":
            domconf='/var/cpanel/userdata/'+alluserdata[domain][1]+'/'+alluserdata[domain][3]+'_SSL'
            if os.path.exists(domconf):
                ssldom[domain]=[alluserdata[domain][3],alluserdata[domain][5]]
        if alluserdata[domain][2] == "sub":
            domconf='/var/cpanel/userdata/'+alluserdata[domain][1]+'/'+alluserdata[domain][0]+'_SSL'
            if os.path.exists(domconf):
                ssldom[domain]=[alluserdata[domain][0],alluserdata[domain][5]]
    return ssldom

def build_ssl_cert(domain):
    userdata=get_vhost_data()
    ssldoms=get_ssl_domains()
    if domain in ssldoms:
        user=userdata[domain][1]
        dfile=ssldoms[domain][0]
        domconf='/var/cpanel/userdata/'+user+'/'+dfile+'_SSL'
    

    print "CC "+domconf
    if os.path.exists(domconf):
        with open(domconf) as domfile:
            lines=domfile.read().splitlines()
        cafile=""
        for  line in lines:
            if "sslcacertificatefile:" in line:
                x=line.split(":")
                cafile=x[1].strip()
            if "sslcertificatefile:" in line :
                y=line.split(":")
                cert=y[1].strip()
            if "sslcertificatekeyfile:" in line:
                z=line.split(":")
                key=z[1].strip()
        with open(cert)as certfile:
            pem=certfile.read()
        if os.path.exists(cafile):
            makeca="ln -sf "+cafile+ " _usr_local_nginx_conf_ssl.ca.d_"+domain+"_ca-bundle"
            makeca="ln -sf "+cafile+ "/etc/nginx/ssl.cert.d/"+domain+"_ca-bundle"
            subprocess.call(makeca,shell=True)
            print "Creating CA-Bundle For "+domain+" /etc/nginx/ssl.cert.d/"+domain+"_ca-bundle"
            pem += "\n"
            with open(cafile,'r')as cafile:
                pem += cafile.read()
	makepem="/etc/nginx/ssl.cert.d/"+domain+"_SSL_cert"
        print "Creating CERT File  For "+domain+" /etc/nginx/ssl.cert.d/"+domain+"_SSL_cert"
        with open(makepem,'w') as writecrt:
            writecrt.write(pem)
        if os.path.exists(key):
	    print "KEY ",key
            makekey="ln -sf "+key+" _usr_local_nginx_conf_ssl.key.d_"+domain+"_key"
	    makekey="ln -sf "+key+" /etc/nginx/ssl.cert.d/"+domain+"_key"
            subprocess.call(makekey,shell=True)
            print "Creating KEY File  For "+domain+" /etc/nginx/ssl.cert.d/"+domain+"_key"
    else:
        print "SSl Configuration file is missing "
        sys.exit()






dominio = sys.argv[1]


build_ssl_cert(dominio)
