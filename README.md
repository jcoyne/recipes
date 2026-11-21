# Import recipes by doing

```
rake import:ba[http://example.com/my-favorite-recipe]
```

```
rake import:ec[https://www.epicurious.com/recipes/food/views/pitaquiles-pita-in-tomato-sauce]
```

Each import saves a copy of the recipe's image in `app/assets/images/recipes/`, shrunk to 1200px
wide, re-encoded as AVIF and named by the MD5 of the result. This needs libvips with AVIF
support (`brew install vips`). To fetch images for recipes that don't have one yet:

```
rake recipes:download_images
```

# Browse them

Run `bin/dev` and open http://localhost:3000
