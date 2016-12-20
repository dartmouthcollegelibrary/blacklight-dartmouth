# Usage: traject -c config/traject/mapping_test.rb [list of paths to MARC files]
# bundle exec traject -d -c ./config/traject/mapping_test.rb ./testdata/aacr2testrecordsutf8.out

# $: means $LOAD_PATH, .unshift means add to the beginning, need this line to find translation maps
$:.unshift './config'
$:.unshift './app/models'

require 'library_stdnums'
require 'traject/marc_reader'
require 'traject/debug_writer'
require 'traject/macros/marc21'

require 'dcl_formats'
extend DclFormats
require 'dcl_macros'
extend DclMacros

settings do
  provide "reader_class_name", "Traject::MarcReader"
  provide "marc_source.type", "binary"
  provide "writer_class_name", "Traject::DebugWriter"
  provide "output_file", "debug_output2.txt"
  provide 'processing_thread_pool', 2
  provide 'log.file', 'traject.log'
  provide 'log.error_file', 'traject_error.log'
end

to_field "id", record_id

to_field "format", get_format