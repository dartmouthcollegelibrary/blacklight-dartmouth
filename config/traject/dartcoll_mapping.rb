# Usage: traject -c config/traject/dartcoll_mapping.rb [list of paths to MARC files]

require 'traject/marc_reader'
require 'traject/debug_writer'

# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require_relative '../../app/models/dcl_macros'
extend DclMacros

settings do
  provide "reader_class_name", "Traject::MarcReader"
  provide "marc_source.type", "binary"
  provide "writer_class_name", "Traject::DebugWriter"
  provide "output_file", "debug_output.txt"
  provide 'processing_thread_pool', 2
  provide 'log.file', 'traject.log'
end

to_field "id", record_id

# An exact literal string, always this string:
to_field "source_t",              literal("traject_test")
