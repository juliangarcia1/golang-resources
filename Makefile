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
