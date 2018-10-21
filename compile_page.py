import click
import jinja2
import json
import os
import pathlib
from bs4 import BeautifulSoup
from markdown import markdown
from shutil import copyfile
import frontmatter
import datetime

def change_file_extension(p, ext):
	basefilename = os.path.splitext(os.path.basename(p))[0]
	filename = basefilename + ext
	filename = os.path.join(os.path.dirname(p), filename)
	return filename

def render_page(templates, template, **data):
	environment = jinja2.Environment(loader=jinja2.FileSystemLoader(templates))
	return environment.get_template(template).render(data)

@click.command()
@click.option('--templates', help='Where the templates are located')
@click.option('--config', help='The default values for the config')
@click.argument('page')
def main(templates, config, page):	
	with open(config) as defaults_file:
		default_config = json.load(defaults_file)
	raw_markdown = frontmatter.load(page)
	md = raw_markdown.content
	
	merged = dict()
	merged.update(default_config)
	merged.update(raw_markdown)

	merged['content'] = BeautifulSoup(markdown(md), 'html.parser').prettify()

	if 'canonical' not in raw_markdown.keys():
		merged['canonical'] = default_config['canonical'] + change_file_extension(page, '.html')
		
	merged['year'] = datetime.datetime.now().year	
	merged['templates'] = templates

	final = render_page(**merged)
	print(final)

if __name__ == "__main__":
	main()
