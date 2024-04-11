build_folder = ./build
build_name = main
mockery_folder_target = ./internal/app
test:
	go test -v ./...

lint:
	golangci-lint run

run:
	go run main.go

build:
	go build -o $(build_folder)/$(build_name) main.go

file = ./internal/app/app.go
create-tests-for-file:
	gotests -w -all $(file)
#  Example: make create-mocks-for-file file=internal/repositories/database.go	
# file = internal/repositories/database.go
# create-mocks-for-file:
# 	gotests -w -all -exclude=.*_test.go $(file)


package_folder = ./internal/repositories
interface_name = DatabaseInterface
filename_containing_interface = database.go
package_name = database
output_folder = ./mocks/${package_name}
create-mocks: 
	mockery --name=Database --output=$(mockery_folder_target)/database --inpackage --case=underscore
	mockery --dir=${package_folder} \
	--name=${interface_name}  \
	--filename${filename_containing_interface} \
	--output=${output_folder}  \
	--outpkg=${package_name}

# When local libraries are not working properly or 
# corrupted or modified by hand or for testing purposes
reset-go-libraries: 
	go clean --modcache
	go mod tidy
	# After this you need to restart/reload your IDE
	# go mod vendor
	# go mod verify

# Create a dynamodb table with fields ID and Name as primary key
create-dynamodb-table:
	aws dynamodb create-table \
	--table-name TestTable \
	--attribute-definitions \
	AttributeName=ID,AttributeType=S \
	AttributeName=Name,AttributeType=S \
	--key-schema \
	AttributeName=ID,KeyType=HASH \
	AttributeName=Name,KeyType=RANGE \
	--provisioned-throughput \
	ReadCapacityUnits=5,WriteCapacityUnits=5 \
	--endpoint-url http://localhost:8000

# Create a SQS queue
queue_name = TestQueue
create-sqs-queue:
	aws sqs create-queue \
	--queue-name $(queue_name) \
	--endpoint-url http://localhost:4566

# Create a lambda function code using echo to a temp file, 
# add it to a zip file and then remove the code
create-lambda-zip:
	echo "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}" > $(build_folder)/main.go
	zip $(build_folder)/$(build_name) $(build_folder)/main.go
	rm $(build_folder)/main.go

# Create a lambda function
function_name = TestFunction
create-lambda-function:
	aws lambda create-function \
	--function-name $(function_name) \
	--runtime go1.x \
	--role arn:aws:iam::000000000000:role/lambda-role \
	--handler main \
	--zip-file fileb://$(build_folder)/$(build_name) \
	--endpoint-url http://localhost:4566

# Create a docker-compose file with localstack using echo
create-docker-compose:
	echo "version: '3'\n\nservices:\n  localstack:\n    image: localstack/localstack\n    ports:\n      - \"4566-4599:4566-4599\"\n    environment:\n      - SERVICES=sqs,dynamodb,lambda\n      - DOCKER_HOST=unix:///var/run/docker.sock\n      - LAMBDA_EXECUTOR=docker\n      - LOCALSTACK_HOSTNAME=localstack" > docker-compose.yml

compare-json:
	@echo "Comparing JSON files"
	@diff -u <(jq --sort-keys . $(file1)) <(jq --sort-keys . $(file2)) || true