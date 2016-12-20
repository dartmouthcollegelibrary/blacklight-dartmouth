# marc_indexer.rb

Detailed documentation for the version of `marc_indexer.rb` from commit [`a160e49`](https://github.com/dartmouthcollegelibrary/blacklight-dartmouth/blob/a160e494b41c2d2b9c46b62a590718af4e381054/app/models/marc_indexer.rb).

For further information, see the [Traject project documentation](https://github.com/traject/traject).

## Notes

Load additional files that contain customized Traject configurations:

* the `config` directory
* the `DclMacros` module defined within [`dcl_macros.rb`](https://github.com/dartmouthcollegelibrary/blacklight-dartmouth/blob/a160e494b41c2d2b9c46b62a590718af4e381054/app/models/dcl_macros.rb)
* the `Formats` module defined by the [blacklight-marc](https://github.com/projectblacklight/blacklight-marc/blob/dace1527250781abd76989094f7729163166a3a0/lib/blacklight/marc/indexer/formats.rb) plugin for mapping format types

Create a Traject indexing specification called `MarcIndexer`, based off of the template established by the [blacklight-marc](https://github.com/projectblacklight/blacklight-marc/blob/dace1527250781abd76989094f7729163166a3a0/lib/blacklight/marc/indexer.rb) plugin. Every indexing rule defined below will apply to each processed record, if applicable.

```ruby
$:.unshift './config'
require_relative 'dcl_macros'

class MarcIndexer < Blacklight::Marc::Indexer
  # this mixin defines lambda factory method get_format for legacy marc formats
  include Blacklight::Marc::Indexer::Formats
  include DclMacros

  def initialize
    super
```

Specify that input MARC files will be binary. Allow an unlimited number of records to be skipped by the indexer due to errors.

```ruby
    settings do
      # type may be 'binary', 'xml', or 'json'
      provide "marc_source.type", "binary"
      # set this to be non-negative if threshold should be enforced
      provide 'solr_writer.max_skipped', -1
    end
```

The `to_field` instruction identifies a Solr field to be populated, using a macro referenced by name, or using a block of code that is specified in-line. Here, populate the Solr field `id` by using the macro `record_id`, which is defined in `DclMacros`.

```ruby
    #to_field "id", trim(extract_marc("001"), :first => true)
    to_field "id", record_id
```

For `marc_display`, use the macro `get_xml` (defined by blacklight-marc).

For `text`, use the default Traject macro `extract_all_marc_values` to create a set of subfield data (the macro retrieves data for fields 100-899), and unify that set into a single string, separating each data element with a space.

```ruby
    to_field 'marc_display', get_xml
    to_field "text", extract_all_marc_values do |r, acc|
      acc.replace [acc.join(' ')] # turn it into a single string
    end
```

For `language_facet`, use the default Traject macro `marc_languages` on data extracted from the 008 (bytes 35-37), 041 $a, and 041 $d.

For `format`, use the macro `get_format` (defined by blacklight-marc).

For `isbn_t`:

* Extract data from the 020 $a, keeping each instance of the subfield separate
* Normalize a copy of all gathered ISBN values, using separate functions written to handle standard identifier formats
* Combine the copy with the original set, and deduplicate

```ruby
    to_field "language_facet", marc_languages("008[35-37]:041a:041d:")
    to_field "format", get_format
    to_field "isbn_t",  extract_marc('020a', :separator=>nil) do |rec, acc|
         orig = acc.dup
         acc.map!{|x| StdNum::ISBN.allNormalizedValues(x)}
         acc << orig
         acc.flatten!
         acc.uniq!
    end
```

Here, extract data from the specified subfields. When set to "true", `trim_punctuation` implements a [built-in routine](https://github.com/traject/traject/blob/c23d2045d49ca60be6b70a19e471e739e86b1d51/lib/traject/macros/marc21.rb#L216-L246) for removing certain trailing or leading punctuation.

```ruby
    to_field 'material_type_display', extract_marc('300a', :trim_punctuation => true)

    # Title fields
    #    primary title

    to_field 'title_t', extract_marc('245a')
    to_field 'title_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>false)
    to_field 'title_vern_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>:only)

    #    subtitle

    to_field 'subtitle_t', extract_marc('245b')
    to_field 'subtitle_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>false)
    to_field 'subtitle_vern_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>:only)
```

For `title_addl_t` and `title_added_entry_t`, extract data from the set of subfields specified on each line. `ATOZ` is a short-hand for "all alphabetic subfields" defined by blacklight-marc.

Joining each line with a colon is solely to satisfy Traject syntax -- see the single-line syntax for `title_series_t` -- and does not affect the indexed data itself.

For `title_sort`, use the default Traject macro `marc_sortable_title`, which generates [a version of the title](https://github.com/traject/traject/blob/1da24e2f0efeaa3386f72eeb87053b588561f501/lib/traject/macros/marc21_semantics.rb#L91-L118) without any non-filing characters.

```ruby
    #    additional title fields
    to_field 'title_addl_t',
      extract_marc(%W{
        245abnps
        130#{ATOZ}
        240abcdefgklmnopqrs
        210ab
        222ab
        242abnp
        243abcdefgklmnopqrs
        246abcdefgnp
        247abcdefgnp
      }.join(':'))

    to_field 'title_added_entry_t', extract_marc(%W{
      700gklmnoprst
      710fgklmnopqrst
      711fgklnpst
      730abcdefgklmnopqrst
      740anp
    }.join(':'))

    to_field 'title_series_t', extract_marc("440anpv:490av")

    to_field 'title_sort', marc_sortable_title
```

Extract data from each of the specified subfields. By default, `alternate_script` is "true" and will extract data from linked 880 fields where available. When set to "false", `alternate_script` will exclude linked 880 fields, and when set to "only", it will include 880 fields but not their equivalents.

The macros `marc_sortable_author` and `marc_publication_date` are Traject defaults.

```ruby
    # Author fields

    to_field 'author_t', extract_marc("100abcegqu:110abcdegnu:111acdegjnqu")
    to_field 'author_addl_t', extract_marc("700abcegqu:710abcdegnu:711acdegjnqu")
    to_field 'author_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>false)
    to_field 'author_vern_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>:only)

    # JSTOR isn't an author. Try to not use it as one
    to_field 'author_sort', marc_sortable_author

    # Subject fields
    to_field 'subject_t', extract_marc(%W(
      600#{ATOU}
      610#{ATOU}
      611#{ATOU}
      630#{ATOU}
      650abcde
      651ae
      653a:654abcde:655abc
    ).join(':'))
    to_field 'subject_addl_t', extract_marc("600vwxyz:610vwxyz:611vwxyz:630vwxyz:650vwxyz:651vwxyz:654vwxyz:655vwxyz")
    to_field 'subject_topic_facet', extract_marc("600abcdq:610ab:611ab:630aa:650aa:653aa:654ab:655ab", :trim_punctuation => true)
    to_field 'subject_era_facet',  extract_marc("650y:651y:654y:655y", :trim_punctuation => true)
    to_field 'subject_geo_facet',  extract_marc("651a:650z",:trim_punctuation => true )

    # Publication fields
    to_field 'published_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>false)
    to_field 'published_vern_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>:only)
    to_field 'pub_date', marc_publication_date
```

Extract data from the specified subfields. Setting `first` to "true" means that only data from the first field matched will be extracted.

For `lc_1letter_facet`, the first letter of the extracted data is selected and compared with a Traject construct called a "translation map" in order to retrieve a human-readable label for display in Blacklight. This particular translation map, `callnumber_map`, is [defined by blacklight-marc](https://github.com/projectblacklight/blacklight-marc/blob/b7fde6c238dd5a1cd6a63aae17822ca18659efc7/lib/generators/blacklight/marc/templates/config/translation_maps/callnumber_map.properties).

```ruby
    # Call Number fields
    to_field 'lc_callnum_display', extract_marc('050ab', :first => true)
    to_field 'lc_1letter_facet', extract_marc('050ab', :first=>true, :translation_map=>'callnumber_map') do |rec, acc|
      # Just get the first letter to send to the translation map
      acc.map!{|x| x[0]}
    end

    alpha_pat = /\A([A-Z]{1,3})\d.*\Z/
    to_field 'lc_alpha_facet', extract_marc('050a', :first=>true) do |rec, acc|
      acc.map! do |x|
        (m = alpha_pat.match(x)) ? m[1] : nil
      end
      acc.compact! # eliminate nils
    end

    to_field 'lc_b4cutter_facet', extract_marc('050a', :first=>true)
```



```ruby
    # URL Fields

    notfulltext = /abstract|description|sample text|table of contents|/i

    to_field('url_fulltext_display') do |rec, acc|
      rec.fields('856').each do |f|
        case f.indicator2
        when '0'
          f.find_all{|sf| sf.code == 'u'}.each do |url|
            acc << url.value
          end
        when '2'
          # do nothing
        else
          z3 = [f['z'], f['3']].join(' ')
          unless notfulltext.match(z3)
            acc << f['u'] unless f['u'].nil?
          end
        end
      end
    end

    # Very similar to url_fulltext_display. Should DRY up.
    to_field 'url_suppl_display' do |rec, acc|
      rec.fields('856').each do |f|
        case f.indicator2
        when '2'
          f.find_all{|sf| sf.code == 'u'}.each do |url|
            acc << url.value
          end
        when '0'
          # do nothing
        else
          z3 = [f['z'], f['3']].join(' ')
          if notfulltext.match(z3)
            acc << f['u'] unless f['u'].nil?
          end
        end
      end
    end
  end
end
```
