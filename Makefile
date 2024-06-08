.PHONY: clean  # Phony target for cleanup

main.js:
	elm make elm/Main.elm --output=$@

build: main.js
	webpack

dev: build
	open index.html

clean:
	rm -rf dist
	rm main.js