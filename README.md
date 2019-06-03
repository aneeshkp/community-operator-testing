# community-operator-testing
operator.sh
The script create folder tigerioperators in your home directory and then pull the PR making it available for testing

Usage: ./operator.sh -o parameterA -p parameterB -b parameterC
	-o , operator you are planning to test
	-p pull id from Pull Request
	-b brnachname to pull from 


Example: 
./operator.sh -o "turbonomic" -p 399 -b "t8c-operator-upstream"
