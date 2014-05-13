#!/usr/bin/env ruby
#require 'graphviz'

module MacPorts

	class PortIndex
		attr_accessor :dotpath
		attr_reader :vertices, :nodes
		def initialize(basedir="/opt/local/var/macports/sources/rsync.macports.org/release/tarballs/ports")
			@ports = {}
			File.open(basedir+'/PortIndex'){|f|
			  prev_line = nil
				f.each{|line|
					if line=~/portdir\s([^\s]+)\s/
						portfile = basedir+'/'+$1+'/Portfile'
						name = prev_line.split(/\s/).first
						# look up ports case insensitively because e.g. hs-HTTP is specified
						# as hs-http but sometimes referred to as hs-HTTP
						@ports[name.downcase] = portfile
					end
					prev_line = line
				}
			}
		end
		
		def port_names
		  @ports.keys
		end
		
		def port(name)
			tmp = @ports[name.downcase]
			if tmp.class==String
				tmp = Port.new(name, tmp, self)
				return @ports[name.downcase] = tmp
			elsif tmp.class==Port
				return tmp
			end
			nil
		end
		
		def dep_graph(name, graph=nil, parent=nil, done = {})
			if not graph
				@vertices = 0
				@nodes = 1
				graph = GraphViz.new("G")
				graph.add_nodes(name)
			end
			done[name] = true
			port(name).dependencies.each {|dep_name|
				if not done[dep_name]
					graph.add_nodes(dep_name)
					@nodes+=1
					dep_graph(dep_name, graph, name, done) 
				end
				graph.add_edges(name, dep_name)
				@vertices+=1
			}
		  return graph
		end
	end
	
	class Port
		attr_reader :name, :port_file, :dependencies
		def initialize(name, portfile, portindex)
			@name = name
			@portfile = portfile
			@portindex = portindex
			@dependencies = []
			deps = false
			IO.readlines(@portfile).each {|line|
				deps = true if deps == false && line=~/^depends/
				deps = false if deps == true && line.gsub(/\s/,'').empty?
				if deps
					line.split(/ /).each {|foo|
						if foo=~/port:([^\s]+)/
						  @dependencies << $1
						end
					}
				end
			}
		end
		
		def to_s
			"MacPorts::Port[#{name}]"
		end
	end
end

if __FILE__ == $0
	pi = MacPorts::PortIndex.new()
	graph = pi.dep_graph(ARGV[0])
	graph.output(:png => ARGV[0]+'.png')
	#puts "#{pi.nodes} nodes, #{pi.vertices} vertices"
	begin
  	require 'rbconfig'
  	case RbConfig::CONFIG['host_os']
  	when /^darwin/
  	  system "open #{ARGV[0]}.png"
    when /^linux/
      system "gnome-open #{ARGV[0]}.png"
  	end
  rescue LoadError
    # in this case i don't know how to open a file
  end
end