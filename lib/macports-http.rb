require 'sinatra'
require 'json'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'macports'

$portindex = MacPorts::PortIndex.new

set :public_folder, File.dirname(__FILE__) + '/static_html'

get '/dependencies/*.json' do
  portname = params[:splat].first
  # portname is matched against existing ports and not used directly to open files
  graph = $portindex.dep_graph(portname)
  deps={}
  deps['nodes'] = graph.each_node.keys
  deps['edges'] = graph.each_edge.map{|edge| [edge.node_one, edge.node_two]}
  content_type :json
  JSON.dump deps 
end
