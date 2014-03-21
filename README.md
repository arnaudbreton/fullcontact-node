fullcontact-node
================

Short Node script to query Fullcontact (fullcontact.com) API and retrieve people's information from email

Two modes: test and real, to configure in `config.json`. Default to test.

In real mode, provide a valid API key in `config.json`, key `apiKey`.

In test mode, it parses 10 times the sample `contact.json` provided file and output the same processed result as in real mode. For obvious reasons, the data have been anonymized.

Useful for debugging and fixing data structure and avoid Fullcontact free plan 250 matches limit while testing.

To modify the output columns, modify the personTemplate in `config.json`