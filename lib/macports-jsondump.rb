#!/ust/bin/env ruby
require 'json'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'macports'

js_portindex = {}

pi = MacPorts::PortIndex.new()
pi.port_names.each{ |name|
  js_portindex[name] = pi.port(name).dependencies
}

JSON.dump js_portindex, STDOUT
