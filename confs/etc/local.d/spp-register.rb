#!/usr/bin/ruby

require "dbus"

spp_uuid = '00001101-0000-1000-8000-00805f9b34fb'
spp_opts = {"Name"=>"SerialPort", "AutoConnect"=>true, "Role"=>"server", 
	"Channel"=>1, "RequireAuthentication" => false, "RequireAuthorization" => false}

#nap_uuid= '00001116-0000-1000-8000-00805f9b34fb'
#nap_opts = {"Name" => "nap", "AutoConnet" => true, "Role" => "panu",
#	"Channel" => 2, "RequireAuthentication" => true, "RequireAuthorization" => false}

#gap_uuid = '00001800-0000-1000-8000-00805f9b34fb'
#gap_opts= {"Name" => "GAP", "AutoConnect" => true, "Channel" => 3}

sysbus = DBus::SystemBus.instance
bluez_service = sysbus.service("org.bluez")
bluez_object = bluez_service.object("/org/bluez")
bluez_object.default_iface = "org.bluez.ProfileManager1"

begin
	bluez_object.RegisterProfile("/bluetooth/profile/spp", spp_uuid, spp_opts)
rescue DBus::Error => e
	puts e
end

#begin
#	bluez_object.RegisterProfile("/bluetooth/profile/nap", nap_uuid, nap_opts)
#rescue DBus::Error => e
#	puts e
#end

loop = DBus::Main.new
loop << sysbus
loop.run
