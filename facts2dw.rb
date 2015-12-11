#!/usr/bin/ruby

###########################################################################
#                                                                         #
#   facts2dw.rb  -  Simple script which converts ansible facts into       #
#		    dokuwiki-format and uploads it via			  #
#		    xmlrpc-interface into dokuwiki			  #
#									  #
#   This script uses http-basic-authentication and ssl to login into	  #
#   dokuwiki. Ansible caches all the facts in <ANSIBLE-DIR>/facts	  #
#   so it is quite easy to import all facts into dokuwiki using the	  #
#   following line: for i in `ls *`; do facts2dw.rb $i; done		  #
#									  #
#   To upload all the changes whenever they occur I would recommend       #
#   using inotify.							  #
#									  #
#   It is very easy to change this script to use puppet-facts instead of  #
#   ansible-facts. If puppetdb is installed all the facts can fetched via #
#   the rest interface. It's just a matter of few lines. 		  #
#   Of course the jason-structur will look different, but it will be      #
#   easy to modify this very simple script. I would recommend to 	  #
#   use the debug-code which executes 'pp', to dump the jason-hash.       #
#                                                                         #
#   Copyright (C) 2015 Wolfgang Hotwagner(wolfgang.hotwagner@toscom.at)   #
#                                                                         #
#   This program is free software; you can redistribute it                #
#   and/or modify it under the terms of the                               #
#   GNU General Public License as published by the                        #
#   Free Software Foundation; either version 2 of the License,            #
#   or (at your option) any later version.                                #
#                                                                         #
#   This program is distributed in the hope that it will be               #
#   useful, but WITHOUT ANY WARRANTY; without even the implied            #
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR               #
#   PURPOSE. See the GNU General Public License for more details.         #
#                                                                         #
#   You should have received a copy of the GNU General Public             #
#   License along with this program; if not, write to the Free            #
#   Software Foundation, Inc., 51 Franklin St, Fifth Floor,               #
#   Boston, MA 02110, USA                                                 #
#                                                                         #
###########################################################################

require "xmlrpc/client"
require "openssl"
require "json"
require "pathname"
require 'optparse'
require 'ostruct'


options = OpenStruct.new

###### DEFAULT CONFIG VARIABLES ###########
options.url = 'https://www.bestdokuwikiintheworld.com/dokuwiki/lib/exe/xmlrpc.php'
options.user = 'dwimporter'
options.pass = 'dwimporterpass'
options.namespace = 'inventory:server'
options.debug = 0
options.upload = 1
######## END CONFIG VARIABLES ###########


######### CLASSDEF #######
class AnsibleWiki

def initialize(jsonobject)
	@obj = jsonobject

	generate
end	

def dwpage; @dwpage; end

def generate
	@dwpage = ""

	generateGeneral
	generateOs
	generateBios
	generateProcessor
	generateMemory
	generateNetwork
	generateDisk
end

def generateGeneral
	h5("General")
	tableRow("FQDN",@obj['ansible_fqdn'])
	tableRow("Hostname",@obj['ansible_hostname'])
	tableRow("Domain",@obj['ansible_domain'])
	tableRow("System",@obj['ansible_system'])
	tableRow("Kernel",@obj['ansible_kernel'])
	tableRow("Virtualization Type",@obj['ansible_virtualization_type'])
	tableRow("Virtualization Role",@obj['ansible_virtualization_role'])
	@dwpage += "\n"
end

def generateOs
	h5("Operating System")
	tableRow("Distribution",@obj['ansible_distribution'])
	tableRow("Distribution Version",@obj['ansible_distribution_version'])
	tableRow("Major Version",@obj['ansible_distribution_major_version'])
	tableRow("Release",@obj['ansible_distribution_release'])
	@dwpage += "\n"
end

def generateBios
	h5("Bios")
	tableRow("Name",@obj['ansible_product_name'])
	tableRow("Serial",@obj['ansible_product_serial'])
	tableRow("UUID",@obj['ansible_product_uuid'])
	tableRow("Version",@obj['ansible_product_version'])
	@dwpage += "\n"
end

def generateProcessor
	h5("Prozessor")
	tableRow("Processor",@obj['ansible_processor'])
	tableRow("Cores",@obj['ansible_processor_cores'])
	tableRow("Count",@obj['ansible_processor_count'])
	tableRow("Threads per core",@obj['ansible_processor_threads_per_core'])
	tableRow("VCPUs",@obj['ansible_processor_vcpus'])
	@dwpage += "\n"
end

def generateMemory
	h5("Memory")
	tableRow("Memory Total",@obj['ansible_memtotal_mb'])
	tableRow("Memory Free",@obj['ansible_memfree_mb'])
	tableRow("Swap Total",@obj['ansible_swaptotal_mb'])
	tableRow("Swap Free",@obj['ansible_swapfree_mb'])
	@dwpage += "\n"
end

def generateNetwork
	h5("Network")

	if @obj['ansible_interfaces']
		@obj['ansible_interfaces'].each do | var | 
		anet = "ansible_" + var
		h4(var)
		tableRow("Active",@obj[anet]['active'])
		tableRow("Mac",@obj[anet]['macaddress'])
		tableRow("Mtu",@obj[anet]['mtu'])
		tableRow("Promisc",@obj[anet]['promisc'])
		tableRow("Type",@obj[anet]['type'])
		@dwpage += "\n"

		@dwpage += "^ Address(Ipv4) ^ Netmask ^ Network ^\n"
		if @obj[anet]['ipv4'].nil? || @obj[anet]['ipv4'].empty?
			addr = ""
			net = ""
			mask = ""
		else	
			addr = @obj[anet]['ipv4']['address']
			mask = @obj[anet]['ipv4']['netmask']
			net = @obj[anet]['ipv4']['network']
		end	
		@dwpage += "| #{addr} |  #{mask} |  #{net} |\n"
		@dwpage += "\n"

		@dwpage += "^ Address(IPv6) ^ Prefix ^ Scope ^\n" if @obj[anet]['ipv6'].to_a.length > 0
		@obj[anet]['ipv6'].to_a.each do | v6 |
		@dwpage += "| #{v6['address']} |  #{v6['prefix']} |  #{v6['scope']} |\n"
		end
	end	

	
	@dwpage += "\n"
	end	
end

def generateDisk
	h5("Disks")

	if(@obj['ansible_devices'].is_a?(Hash))
	@obj['ansible_devices'].keys.each do | var |
	h4(var)
	tableRow("Host",@obj['ansible_devices'][var]['host'])
	tableRow("Model",@obj['ansible_devices'][var]['model'])
	tableRow("Removeable",@obj['ansible_devices'][var]['removable'])
	tableRow("Scheduler Mode",@obj['ansible_devices'][var]['scheduler_mode'])
	tableRow("Rotational",@obj['ansible_devices'][var]['rotational'])
	tableRow("Sectors",@obj['ansible_devices'][var]['sector'])
	tableRow("Sectorsize",@obj['ansible_devices'][var]['sectorsize'])
	tableRow("Size",@obj['ansible_devices'][var]['size'])
	@dwpage += "\n"

	h3("Partitions")
	@obj['ansible_devices'][var]['partitions'].to_a.each do | partition |
	h2(partition[0])
	tableRow("Size",@obj['ansible_devices'][var]['partitions'][partition[0]]['size'])
	tableRow("Sectors",@obj['ansible_devices'][var]['partitions'][partition[0]]['sectors'])
	tableRow("Sectorsize",@obj['ansible_devices'][var]['partitions'][partition[0]]['sectorsize'])
	tableRow("Start",@obj['ansible_devices'][var]['partitions'][partition[0]]['start'])
	@dwpage += "\n"
	end

	h3("Mounts")
	@obj['ansible_mounts'].to_a.each do |mount|
	h2(mount['device'])
	tableRow("Mountpoint",mount['mount'])
	tableRow("Filesystem",mount['fstype'])
	tableRow("Mountoptions",mount['options'])
	tableRow("Size available",mount['size_available'])
	tableRow("Size total",mount['size_total'])
	@dwpage += "\n"
	end

	end
#	else
#		print "it's an array\n" 
	end

end

def obj
	return @obj
end

def h5(title)
	@dwpage += "===== #{title} =====\n"
end	

def h4(title)
	@dwpage += "==== #{title} ====\n"
end	

def h3(title)
	@dwpage += "=== #{title} ===\n"
end	

def h2(title)
	@dwpage += "== #{title} ==\n"
end	

def tableRow(name,content)
	@dwpage += "^ #{name} | #{content} | \n" if defined? content
end	

def dump
 	require "pp"
	pp @obj	
end

def to_s
	"#@dwpage"
end
end

######EOF CLASSDEF#######

options.jsonfile = ""

parser = OptionParser.new do |opt|
  opt.banner = "Usage: #{$PROGRAM_NAME} [ options ] <json-file>"
  opt.on('-h', '--help', 'This help screen') do
  	$stderr.puts opt
	exit
  end
  opt.on('-d', '--debug DEBUGLEVEL', 'Debug Level') { |o| options.debug = o.to_i }
  opt.on('-n', '--namespace NAMESPACE', 'Wiki Namespace') { |o| options.namespace = o }
  opt.on('-u', '--host WIKIURL', 'Wiki Url') { |o| options.url = o }
  opt.on('-l', '--login WIKIUSER', 'Wiki User') { |o| options.user = o }
  opt.on('-p', '--pass WIKIPASS', 'Wiki Password') { |o| options.pass = o }
  opt.on('-x', '--upload <0|1>', 'Upload to wiki. default: 1') { |o| options.upload = o.to_i }
  options.help = opt.help
end.parse!

if defined? ARGV[0] and not ARGV[0].nil?
	options.jsonfile = ARGV[0]
	if not File.exist?(options.jsonfile)
		$stderr.puts "File #{options.jsonfile} does not exist"
		exit 1
	end
else
	$stderr.puts options.help
	exit 1
end


$stdout.puts "#{options.jsonfile}\n" if options.debug > 0



begin
	json = File.read(options.jsonfile)
rescue => err
	$stderr.puts "Exception: #{err}"
	err
end	
obj = JSON.parse(json)



aw = AnsibleWiki.new(obj)

if (options.debug > 2)
	aw.dump()
end
#	pn = Pathname.new(options.jsonfile)
#	fqdn = pn.basename
	fqdn = aw.obj['ansible_fqdn']

	if fqdn.nil?
		$stderr.puts "Error: FQDN is not defined!"
		exit 1
	end

puts "#{fqdn}\n" if options.debug > 0



if (options.debug > 1)
print "\n"
print aw
end


if options.upload == 1

 server = XMLRPC::Client.new2(options.url)
 server.instance_variable_get(:@http).instance_variable_set(:@verify_mode, OpenSSL::SSL::VERIFY_NONE)
 server.user = options.user
 server.password= options.pass
 
 begin
     puts server.call("wiki.putPage", options.namespace + ":#{fqdn}",aw.dwpage)
 rescue XMLRPC::FaultException => e
     $stderr.puts "Error:"
     $stderr.puts e.faultCode
     $stderr.puts e.faultString
 end

end 
