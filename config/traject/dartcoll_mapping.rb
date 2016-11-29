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

# this mixin defines lambda factory method get_format for legacy marc formats
require 'blacklight/marc/indexer/formats'
extend Blacklight::Marc::Indexer::Formats

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

# js function in jetty/solr-webapp/webapp/js/lib/jquery.jstree.js
#to_field 'marc_display', get_xml

to_field "text", extract_all_marc_values do |r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

to_field "language_facet", marc_languages("008[35-37]:041a:041d:")

to_field "format", get_format

to_field "isbn_t",  extract_marc('020a', :separator=>nil) do |rec, acc|
  orig = acc.dup
  acc.map!{|x| StdNum::ISBN.allNormalizedValues(x)}
  acc << orig
  acc.flatten!
  acc.uniq!
end

to_field 'material_type_display', extract_marc('300a', :trim_punctuation => true)

# Title fields
#   primary title
to_field 'title_t', extract_marc('245a')
to_field 'title_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>false)
to_field 'title_vern_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>:only)

# subtitle
to_field 'subtitle_t', extract_marc('245b')
to_field 'subtitle_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>false)
to_field 'subtitle_vern_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>:only)

