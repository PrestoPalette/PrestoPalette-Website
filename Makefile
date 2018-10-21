.PHONY: clean prep build watch serve

default: build

venv_directory = ./venv
node_directory = ./node_modules
dist_directory = ./docs

clean:
	@rm -rf $(venv_directory)/
	@rm -rf $(dist_directory)/
	@rm -rf ./.sass-cache/
	@rm -rf $(node_directory)/

prep: $(venv_directory) $(node_directory)

$(node_directory):
	@npm install json markdown-parse

$(venv_directory):
	@python3 -m venv venv && ./venv/bin/pip install click jinja2 jinja2-cli beautifulsoup4 markdown smartypants pyinotify python-frontmatter htmlmin

build_html: $(patsubst src/pages/%.md, $(dist_directory)/%.html, $(wildcard src/pages/*.md))

$(dist_directory)/%.html: src/pages/%.md
	@./venv/bin/python3 compile_page.py --templates ./src/templates/ --config default.json $< | ./venv/bin/htmlmin -s > $@

build: prep

	# prep $(dist_directory) folder
	@rm -rf ./$(dist_directory)/*
	@mkdir -p ./$(dist_directory)/css
	@mkdir -p ./$(dist_directory)/img
	@mkdir -p ./$(dist_directory)/js

	# copy assets
	@cp -a ./src/assets/* ./$(dist_directory)/

	# build the css files
	@scss --style compressed ./src/scss/site.scss ./$(dist_directory)/css/site.css

	# build the html pages
	@$(MAKE) build_html

	# remove map files
	@rm ./$(dist_directory)/css/*.css.map

	@find ./$(dist_directory)/ -name "*.png" -exec optipng {} \;
	@find ./$(dist_directory)/ -name "*.jpg" -exec jpegoptim {} \;

watch: build
	@./venv/bin/python3 -m pyinotify -r -e IN_CLOSE_WRITE -c 'make build' src/

serve: build
	@cd $(dist_directory) && pwd && ./../venv/bin/python3 -m http.server
