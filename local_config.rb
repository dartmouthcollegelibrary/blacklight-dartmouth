# for debugwriter
require 'traject'
require 'traject/marc_reader'
require 'traject/debug_writer'
require 'blacklight'
require 'blacklight/marc'
require './app/models/dcl_macros'
require './app/models/marc_indexer'

settings do
  provide "reader_class_name", "Traject::MarcReader"
  provide "marc_source.type", "binary"
  provide "writer_class_name", "Traject::DebugWriter"
  provide "output_file", "debug_output.txt"
  provide 'processing_thread_pool', 2

  # Right now, logging is going to $stderr. Uncomment
  # this line to send it to a file

  provide 'log.file', 'traject.log'

end

MarcIndexer.new