require 'set'
class LangId
	START_WORD_CHAR, END_WORD_CHAR, ORDER= "<w>", "</w>", 3

	def initialize(*langs)
		@models = {}
		langs.each { |lang| load_model(lang) }
	end

	def init_ngrams
		@ngrams = (0..ORDER).map { |n| 
			if (n == 0)
				Hash.new(1) 
			else
				Hash.new() 
			end
		}
	end

	def fit(model_name, data_path, format = "txt")
		init_ngrams
		words_set = Set.new
		if (File.directory?(data_path))
			real_path = data_path + '/' unless data_path.end_with?('/')
			@current_model = model_name
			Dir.glob(real_path + "*." + format).each { |file_name|
				puts "Analyzing #{file_name}"
				File.open(file_name, 'r:utf-8').each_line { |line|
					text_words = line.gsub(/[^\p{Alnum}\p{Space}]/u, '').split(/\p{Space}/)
					words_set = words_set + text_words.to_set
					text_words.each { |word|
						ORDER.times { |n| build_ngram(n + 1, word) }
					}
				}
			}
			@models[@current_model] = {:ngrams => @ngrams, :avg => @avg_score, :std => @std_score}
		else
			raise "ERROR: #{data_path} is not a directory"
		end
	end

	def save_model
		File.open('models/model_' + @current_model.to_s, 'w') do |file|
			Marshal.dump(@models[@current_model], file)
		end
	end

	def load_model(lang)
		if @models[lang] || File.exists?("models/model_" + lang.to_s)
            @models[lang] ||= Marshal.load(File.open("models/model_" + lang.to_s)) 
            @current_model = lang
    	else
    		puts "WARNING: Unable to find model for language '#{lang}'"
    	end
	end

	def score(word) 
		return nil if (!@current_model)
		chars = [START_WORD_CHAR, word.downcase.split(""), END_WORD_CHAR].flatten
		scores = (1..ORDER).each.map do |n|
			score = 0
			(chars.size - n + 1).times do |i|
				slice = chars[i...i + n]
				history, char = slice[0...slice.size-1], slice.last
				score += Math.log(get_probability(char, history))
			end
			score / chars.size
		end
		return scores.inject(:+).to_f / scores.size
	end

	def score_text(text)
		words = text.encode('utf-8').gsub(/[^\p{Alnum}\p{Space}]/u, '').split(/\p{Space}/)
		scores = words.each.map { |word| score(word) }
		return scores.inject(:+).to_f / scores.size
	end

	def language(text)
		scores = @models.keys.each_with_index.map do |model, index|
			@current_model = model
			score_text(text)
		end
		return @models.keys[scores.each_with_index.max[1]]
	end

	def build_ngram(n, word)
		if (n == 1)
			@ngrams[0][START_WORD_CHAR] += 1
			@ngrams[0][END_WORD_CHAR] += 1
			word.split.each { |char| @ngrams[0][char] += 1 }
		else
			chars = [START_WORD_CHAR, word.downcase.split(""), END_WORD_CHAR].flatten
			(chars.size - n + 1).times do |i|
				slice = chars[i...i + n]
				history, char = slice[0...slice.size - 1].join, slice.last

				if (@ngrams[n - 1][history])
					@ngrams[n - 1][history][char] += 1
				else
					@ngrams[n - 1][history] = Hash.new(1)
					@ngrams[n - 1][history][char] = 1
				end
				@ngrams[n - 1][history]['sum'] += 1
			end
		end
	end

	def get_probability(char, history = '')
		n = history.size
		if (n == 0)
			return @models[@current_model][:ngrams][n][char].to_f / @models[@current_model][:ngrams][n].values.inject(:+).to_f
		else
			if (@models[@current_model][:ngrams][n][history])
				return @models[@current_model][:ngrams][n][history][char].to_f / @models[@current_model][:ngrams][n][history]['sum']
			else
				return 0.01
			end
		end
	end

	private :init_ngrams, :score, :score_text, :build_ngram, :get_probability
end