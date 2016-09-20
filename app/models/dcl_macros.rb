
module DclMacros

  #Find the record id, remove leading . and strip trailing check digit.
  def record_id
    extractor = Traject::MarcExtractor.new("991a", :first => true)
    lambda do |record, accumulator|
      accumulator << extractor.extract(record).first.slice(1..8)
    end
  end
  
end