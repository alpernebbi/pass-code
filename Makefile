all:
	@echo "pass-code is a shell script, so there is nothing to do."

test:
	$(MAKE) -C tests

lint:
	shellcheck -s bash code.bash

.PHONY: all test lint
