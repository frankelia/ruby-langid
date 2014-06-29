require './langid.rb'

# we are gonna load some already trained models
train = false

# this will try to load this models looking for files name 
# model_en, model_es, and so on in the models directory
# if they are not found the execution will continue without
# loading the missing models
p = LangId.new(:en, :es, :it, :de, :fr)

# a set of sentence to test
sentences = [
	"New York è una città degli Stati Uniti d'America. La città è una delle più grandi al mondo",
	"Gli abitanti di New York si chiamano New Yorkers, in italiano newyorkesi o raramente in novaiorchesi.",
	"Italienisch ist eine Sprache aus dem romanischen Zweig der indogermanischen Sprachen.",
	"The standard Italian language has a poetic and literary origin in the twelfth century, and the modern standard of the language was largely shaped by relatively recent events.",
	"Pedro Sánchez ganó en avales en 12 comunidades y arrasó en Andalucía",
	"Les Britanniques pessimistes sur le poids de Cameron au sein de l'Union européenne"
]

if (train) 
	# train a model named :en from text file contained in the directory 'english_texts'
	p.fit(:en, 'english_texts')
	# saves the current model in the models folder
	p.save_model

	# same for all other languages
	p.fit(:es, 'spanish_texts')
	p.save_model
	p.fit(:de, 'german_texts')
	p.save_model
	p.fit(:fr, 'french_texts')
	p.standardve_model
	p.fit(:it, 'italian_texts')
	p.save_model
end

sentences.each do |sentence| # lets classify a couple of sentences
	puts p.language(sentence)
end