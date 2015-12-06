function showRecipe(index) {
    element = document.getElementById('recipe');
    recipe = recipes[index];

    ingredients = recipe.ingredients.map(function(i) {
      return `${i.quantity} ${i.unit} ${i.name}`
    });
    ingredient_list = `<ul><li>${ingredients.join('</li><li>')}</li></ul>`
    preparation = `<p>${recipe.preparation_steps.join('</p><p>')}</p>`
    element.innerHTML = `<div><h2><a href="${recipe.link}">${recipe.title}</a></h2>
      <img src="${recipe.thumbnail}">
      <div class="row">
        <div class="ingredients-container col-xs-12 col-sm-4 col-md-5 col-lg-5">
          <h3>Ingredients</h3>
          ${ingredient_list}
        </div>
        <div class="prep-steps-container col-xs-12 col-sm-8 col-md-7 col-lg-7">
          <h3>Preparation</h3>
          ${preparation}
        </div>
      </div>
    `;
}

function route() {
    if (currentState() === null) {
        defaultRoute();
    } else
        showRecipe(currentPage());
}

function currentPage() {
    return boundsCheck(parseInt(currentState()));
}

function gotoPage(newPage) {
    index = boundsCheck(newPage)
    history.pushState({ index: index }, `page ${index}`, `#${index}`);
    route();
}

function boundsCheck(index) {
      if (isNaN(index))
          return 0;
      else if (index >= recipes.length)
          return recipes.length - 1;
      else if (index < 0)
          return 0;
      return index;
}

function currentState() {
    if (history.state)
        return history.state.index
    return null
}


function defaultRoute() {
    index = Math.floor(Math.random() * recipes.length);
    gotoPage(index);
}

var recipes = [];

$.getJSON("/recipes").done(function(data) {
    recipes = data.recipes;
    route();
});

