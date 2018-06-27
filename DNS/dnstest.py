try:
    import dns.resolver
except:
    print "you need to install dnspython : sudo easy_install dnspython" 
    raise
import commands


def dnstest(hostname, name, dnsip):
    print "testing : " + name + " ( " + dnsip + " ) "
    res = dns.resolver.Resolver(configure=False)
    res.nameservers = [dnsip]
    ip = res.query(hostname)[0].address
    print ip
    ping = commands.getstatusoutput("ping -c 5 -q " + ip)[1]
    print ping
    print "----------------------------------"

def test(hostname, provider):
    print "====== testing : " + hostname + " " + provider + " ==========="
    output = ""
    nameservers = [{'ip': '208.67.222.222', 'name':'OpenDNS'}, {'ip': '8.8.8.8', 'name':'Google'}]
    for nameserver in nameservers:
        dnstest(hostname, nameserver['name'], nameserver['ip'])

    dnstest(hostname, "default", str(dns.resolver.Resolver().nameservers[0]))
    print "====================================="


test('cdn.thaindian.com', 'Internap')
test('profile.ak.fbcdn.net', 'Akamai')
test('cdn.twitbooth.com', 'Amazon Cloudfront')
