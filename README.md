# Import recipes by doing

```
rake import:ba[http://example.com/my-favorite-recipe]
```

```
rake import:ec[https://www.epicurious.com/recipes/food/views/pitaquiles-pita-in-tomato-sauce]
```

Each import saves a copy of the recipe's image in `app/assets/images/recipes/`, named by the MD5
of its content. To fetch images for recipes that don't have one yet:

```
rake recipes:download_images
```

# Browse them

Run `bin/dev` and open http://localhost:3000
