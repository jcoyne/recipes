# Recipes

A static recipe site (`site/`) plus Ruby tooling for importing recipes into it.

- `site/index.html`, `app.js`, `app.css` — the front end. It asks for a password (`recipes`) before
  showing anything; this only keeps casual scrapers away and is not real security.
- `site/recipes/<md5>.b64` — one Base64-encoded JSON file per recipe, named by the MD5 of its
  contents. `site/recipes/index.json` lists them, oldest first.
- `site/images/<md5>.avif` — a local copy of each recipe's image, shrunk to 1200px wide.

## Setup

Requires Ruby 4 and libvips with AVIF support (`brew install vips`), then:

```
bundle install
```

## Import recipes

Most recipe sites (Bon Appétit, NYT Cooking, ...) publish a schema.org Recipe as JSON-LD, which
`import:ld` reads (`import:ba` is the same thing):

```
rake import:ld[https://www.bonappetit.com/recipe/make-ahead-gravy]
rake import:ec[https://www.epicurious.com/recipes/food/views/pitaquiles-pita-in-tomato-sauce]
```

Each import writes the recipe file, downloads its image and updates `index.json`. To fetch images
for recipes that don't have one yet:

```
rake recipes:download_images
```

## Preview and deploy

```
rake serve    # http://localhost:8000
rake deploy   # copies site/ to ../jcoyne.github.io/recipes; commit and push there to publish
rake test
```
