#Setup Environment
- Make sure the Microsoft Learn MCP server is available to use
- Make sure Microsoft GraphRAG is installed on the system under the user, python -m graphrag --help will show the available commands
- Create a folder for memory

#Configure GraphRAG
##Help information
- All GraphRAG methods have a --help argument that can be used to learn about the tool use, including base graphrag.exe
##Instructions
- Initialize Microsoft GraphRAG using graphrag init
- Modify the settings.yaml file
    - Set the default_chat_model
		- model: gpt-4o
		- deployment_name: gpt-4o
		- api_base: https://aoai-moderniazationapp.openai.azure.com
		- api_version: 2025-01-01-preview
    - Set the default_embedding_model model
		- model: text-embedding-3-small
		- deployment_name: text-embedding-3-small
		- api_base: https://aoai-moderniazationapp.openai.azure.com
		- api_version: 2025-01-01-preview
    - Set the input file_type to JSON and remove the file_pattern parameter, use the following metadata parameters: path, artifact_type, class_name, method_name
    - Replace the default entity_types with the following: class,method,comments,attributes,properties,datastore
- Make sure a .env file is created with a place holder for GRAPHRAG_API_KEY
- Create a graphrag folder to store the graphrag related data. 
##Code Chunking Strategy
- Create a python script to iterate over a code repo and create chunks for the repo by class and method, 
    - The chunks should be stored in a json file for indexing by Microsoft GraphRAG
    - The json objects should have the following properties: id, path, artifact_type, class_name, method_name, text
##Output
- Remind the user to update the GRAPHRAG_API_KEY in the .env file, include the file path to the .env file for easy access