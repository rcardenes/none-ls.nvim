.PHONY: test test-file install-hooks check clean autogen

test:
	@fail=0; for file in $$(find test/spec -name '*_spec.lua' | sort); do \
		echo "Running $$file"; \
		nvim --headless --noplugin -u test/minimal_init.lua -c "lua MiniTest.run_file('$$file')" || fail=1; \
	done; \
	exit $$fail

test-file:
	nvim --headless --noplugin -u test/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

install-hooks:
	pre-commit install --install-hooks

check:
	pre-commit run --all-files

clean:
	rm -rf .tests/

# do not run manually! (runs via CI)
autogen:
	bash scripts/autogen.sh
