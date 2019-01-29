.PHONY: all lint test coverage

all: lint test

lint:
	vimlparser plugin/*.vim autoload/**/*.vim ftplugin/*.vim syntax/*.vim test/.themisrc > /dev/null
	vint plugin autoload ftplugin syntax

test:
	themis

coverage:
	mkdir -p build
	rm -f ./build/caverage.xml ./build/profile.txt ./build/.coverage.covimerage
	PROFILE_LOG=./build/profile.txt themis
	covimerage write_coverage ./build/profile.txt --data-file ./build/.coverage.covimerage
	coverage xml -o ./build/caverage.xml
	coverage report
