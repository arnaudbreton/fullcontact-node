config = require './config.json'
json2csv = require 'json2csv'
FullContactApi = require('fullcontact-api')

countLine = 0
countCall = 0
personsProcessed = []
personProcessedTemplate = config.personTemplate

class FullContactPersonApi
	constructor: (apiKey) ->
		if apiKey?
			@client = new FullContactApi(apiKey)

	# Process a fullcontact person model to map data to our own model
	processFullContactPerson: (person) ->
		personProcessed = JSON.parse(JSON.stringify(personProcessedTemplate));

		return if not person.contactInfo?
		personProcessed.fullName = person.contactInfo.fullName

		if person.contactInfo.websites?
			for website in person.contactInfo.websites
				personProcessed.websites.push website.url
			personProcessed.websites = personProcessed.websites.join(',')

		if person.organizations?
			for organization in person.organizations
				if organization.current
					personProcessed.currentOrganization = organization.name + "/" + organization.title
					break

		if person.socialProfiles?
			for socialProfile in person.socialProfiles
				if socialProfile.type is "twitter"
					personProcessed[socialProfile.type + '/bio'] = socialProfile.bio if socialProfile.bio
					personProcessed[socialProfile.type + '/followers'] = socialProfile.followers if socialProfile.followers
					personProcessed[socialProfile.type + '/following'] = socialProfile.following if socialProfile.following
				else if socialProfile.type is "linkedin"	
					personProcessed[socialProfile.type + '/bio'] = socialProfile.bio if socialProfile.bio
					personProcessed[socialProfile.type + '/url'] = socialProfile.url if socialProfile.url

		personProcessed

	queryFullContact: (email) ->
		if not @client?
			console.error 'No client. Forgot to provide API key ?'
			return

		@client.person.findByEmail(email, (err, person) =>
			countCall++
			if err or String(person.status).charAt(0) is '4'
				console.error email, 'Error', err or "#{person.status} #{person.message}"
			else
				personsProcessed.push @processFullContactPerson(person)

			# TODO: Quick & Dirty: to improve; 
			# Transform callbacks into promises.
			if countLine is countCall
				json2csv {data: personsProcessed, fields: Object.keys(personProcessedTemplate)}, (err, csv) ->
					if err
						console.error(err)
					else 
						console.log(csv)

		)

config.mode = "test" if not config.mode

# Real mode
if config.mode is 'real'
	Readline = require 'readline'
	fullcontactPersonApi = new FullContactPersonApi(config.apiKey)

	rl = Readline.createInterface({
	  input: process.stdin,
	  output: process.stdout,
	  terminal: false
	})

	rl.on 'line', (email) ->
		countLine++
		fullcontactPersonApi.queryFullContact(email)

# Test mode
else if config.mode is 'test'
	fullcontactPersonApi = new FullContactPersonApi
	fs = require 'fs'

	file = __dirname + '/contact.json';
	 
	fs.readFile file, 'utf8', (err, data) ->
		if (err)
			console.log('Error: ' + err);
			return;

		data = JSON.parse(data)

		for i in [1..10]
			personsProcessed.push fullcontactPersonApi.processFullContactPerson(data)

		json2csv {data: personsProcessed, fields: Object.keys(personProcessedTemplate)}, (err, csv) ->
			if err
				console.error(err)
			else 
				console.log(csv)
else
	console.error "#{config.mode} is invalid"

	

