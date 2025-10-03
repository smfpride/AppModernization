---
mode: agent
---
#Index Codebase
- GraphRag is already installed on the system under the user, python -m graphrag --help will show the available commands
##Tune GraphRAG
- Fine tune the GraphRAG prompts using graphrag prompt-tune, be sure to use the parameters below
    - the --config argument should point to the settings.yaml
    - the --domain should be "software code like C# or Java"
    - use the --discover-entity-types argument
##Indexing Instructions
- Clone the github repo, https://github.com/airsonic-advanced/airsonic-advanced, to a subfolder called airsonic, if not already cloned.
- Index the repo with Microsoft GraphRAG by using graphrag index
    - the --config argument should point to the settings.yaml
    - the --method argument should be fast
	- the --output argument should be 'graphrag\output'
    - include the --verbose argument
- Review the indexing-engine.log to see the results or any errors
##Explain Codebase
- Ask GraphRAG to explain how the application is structured and what it does
    - Store the explanation at `memory/Graph_Explanation.md`