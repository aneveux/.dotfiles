.PHONY: test doctor

test:
	@bash tests/hook-contract-test.sh

doctor: test
	@cc-safety-net doctor
	@cc-safety-net rule verify -g
