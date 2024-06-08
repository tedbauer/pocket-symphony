.PHONY: clean  # Phony target for cleanup

build:
	elm make elm/Main.elm --output=main.js
	webpack

dev: build
	open index.html

clean:
