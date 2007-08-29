require 'graphviz'

def gv_escape(s)
	'"'+s+'"'
end

module MacPorts

	class PortIndex
		attr_accessor :dotpath
		attr_reader :vertices, :nodes
		def initialize(basedir="/opt/local/var/macports/sources/rsync.macports.org/release/ports")
			@ports = {}
			File.open(basedir+'/PortIndex'){|f|
				f.each{|line|
					if line=~/portdir\s([^\s]+)\s/
						portfile = basedir+'/'+$1+'/Portfile'
						name = $1.split(/\//)[1]
						@ports[name] = portfile
					end
				}
			}
		end
		
		def port(name)
			tmp = @ports[name]
			if tmp.class==String
				tmp = Port.new(name, tmp, self)
				return @ports[name] = tmp
			elsif tmp.class==Port
				return tmp
			end
			nil
		end
		
		def dep_graph(name, graph=nil, parent=nil, done = {})
			if not graph
				@vertices = 0
				@nodes = 1
				graph = GraphViz.new("G", 'path'=>@dotpath)
				graph.add_node(gv_escape(name))
			end
			done[name] = true
#			graph.add_edge(gv_escape(parent), gv_escape(name)) if parent
			
			port(name).dependencies.each {|dep_name|
				if not done[dep_name]
					graph.add_node(gv_escape(dep_name))
					@nodes+=1
					dep_graph(dep_name, graph, name, done) 
				end
				graph.add_edge(gv_escape(name), gv_escape(dep_name))
				@vertices+=1
			}
		  return graph
		end
	end
	
	class Port
		attr_reader :name, :port_file, :dependencies
		def initialize(name, portfile, portindex)
			@name = name
			@portfile = portfile.untaint
			@portindex = portindex
			@dependencies = []
			deps = false
			more_deps = false
			IO.readlines(@portfile).each {|line|
				deps = true if deps == false and line=~/^depends/
				if deps
					line.split(/ /).each {|foo|
						foo=~/port:([^\s]+)/
						@dependencies << $1 if $1
					}
						break unless line=~/\\/
				end
			}
		end
		
		def to_s
			"MacPorts::Port[#{name}]"
		end
	end
end

if __FILE__ == $0
	pi = MacPorts::PortIndex.new
	puts pi.port(ARGV[0]).dependencies
	graph = pi.dep_graph(ARGV[0])
	graph.output(:output=>'png', :file=>ARGV[0]+'.png')
	puts "#{pi.nodes} nodes, #{pi.vertices} vertices"
end