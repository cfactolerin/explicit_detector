require "google/cloud/vision"
require 'csv'

@image_path = ARGV[0]
@explicit_list = CSV.read('explicit_list.csv').flatten
@label_result = false

Google::Cloud::Vision.configure do |vision|
  vision.credentials = '/Users/cris/fuga/git/explicit_detector/credentials.json'
end

def detect_labels
  image_annotator = Google::Cloud::Vision.image_annotator

  response = image_annotator.label_detection(
      image:       @image_path,
      max_results: 30
  )

  puts "Detected Labels:"
  matches = []
  response.responses.each do |res|
    res.label_annotations.each do |label|
      l = label.description.downcase
      puts l
      matches << l if @explicit_list.include?(l)
    end
  end
  puts "\n\n"

  puts "Explicit objects found on image: #{matches.join(', ')}"
  @label_result = matches.any?
end

def detect_explicit
  puts "Detecting explicits using safe search..."
  image_annotator = Google::Cloud::Vision.image_annotator

  response = image_annotator.safe_search_detection image: @image_path

  matches = []
  response.responses.each do |res|
    safe_search = res.safe_search_annotation

    # puts "Adult:    #{safe_search.adult}"
    # puts "Spoof:    #{safe_search.spoof}"
    # puts "Medical:  #{safe_search.medical}"
    # puts "Violence: #{safe_search.violence}"
    # puts "Racy:     #{safe_search.racy}"

    result = {
      'adult_content'   => safe_search.adult,
      'racy_content'    => safe_search.racy,
      'violent_content' => safe_search.violence
    }

    match_criteria = ['VERY_LIKELY', 'POSSIBLE']

    result.each_pair do |k, v|
      matches << [k, v] if match_criteria.include?(v.to_s)
    end
  end

  puts "Match found: #{matches}\n\n"
  @explicits = matches.any?
end

def calculate_score
  @score = 0
  @score += 50 if @label_result
  @score += 50 if @explicits
end

detect_labels
detect_explicit
calculate_score

puts "\nEvaluation: This image has #{@score}% chance of being an explicit image.\n\n"
