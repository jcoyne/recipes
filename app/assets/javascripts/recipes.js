// Recipe browser: a small client-side router over the JSON API.
//   /, /recipes      -> list of recipes
//   /recipes/:id     -> a single recipe
// Recipe text comes from scraped sites, so it is only ever inserted as text, never as HTML.

const app = document.getElementById("app");
const prevLink = document.querySelector('[data-nav="prev"]');
const nextLink = document.querySelector('[data-nav="next"]');
const brandLink = document.querySelector('[data-nav="list"]');
const recipeNav = document.querySelector(".site-header nav");

// A light password gate to keep casual scrapers out. This is NOT security: the password is
// only Base64-encoded here, and the JSON API itself is not protected.
const PASSWORD_B64 = "cmVjaXBlcw==";
const UNLOCKED_KEY = "recipes-unlocked";

let unlocked = false;
try {
  unlocked = sessionStorage.getItem(UNLOCKED_KEY) === "1";
} catch {
  // Storage unavailable (e.g. blocked); ask for the password on each page load instead.
}

function passwordMatches(value) {
  try {
    return btoa(value) === PASSWORD_B64;
  } catch {
    return false; // btoa throws on characters outside Latin-1, which can't match anyway
  }
}

function unlock() {
  unlocked = true;
  try {
    sessionStorage.setItem(UNLOCKED_KEY, "1");
  } catch {
    // Not remembered; the gate will reappear on the next page load.
  }
}

let recipesPromise;

function loadRecipes() {
  recipesPromise ??= fetch("/recipes.json", { headers: { Accept: "application/json" } })
    .then((response) => {
      if (!response.ok) throw new Error(`The server responded with ${response.status}`);
      return response.json();
    })
    .then((data) => data.recipes)
    .catch((error) => {
      recipesPromise = undefined; // allow a retry on the next navigation
      throw error;
    });
  return recipesPromise;
}

// Build an element: h("a", { href: "/x" }, "text", childNode)
function h(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [name, value] of Object.entries(attrs)) {
    if (value !== undefined && value !== null && value !== false) el.setAttribute(name, value);
  }
  el.append(...children.flat().filter((child) => child !== undefined && child !== null));
  return el;
}

const recipePath = (recipe) => `/recipes/${encodeURIComponent(recipe.id)}`;

function routeFor(pathname) {
  const match = pathname.match(/^\/recipes\/([^/]+)\/?$/);
  if (match) return { name: "show", id: decodeURIComponent(match[1]) };
  return { name: "list" };
}

function setNeighbor(link, recipe) {
  link.hidden = !recipe;
  if (recipe) link.href = recipePath(recipe);
}

function updateNav(route, recipes, index) {
  if (route.name === "list") brandLink.setAttribute("aria-current", "page");
  else brandLink.removeAttribute("aria-current");

  const showing = route.name === "show" && index >= 0;
  setNeighbor(prevLink, showing ? recipes[index - 1] : undefined);
  setNeighbor(nextLink, showing ? recipes[index + 1] : undefined);
}

function listView(recipes) {
  document.title = "Recipes";
  if (recipes.length === 0) {
    return [h("h1", { tabindex: "-1" }, "Recipes"), h("p", {}, "No recipes yet. Import one with bin/rake import:ba[URL].")];
  }
  return [
    h("h1", { tabindex: "-1" }, "Recipes"),
    h("ul", { class: "recipe-list" }, recipes.map((recipe) => h("li", {}, h("a", { href: recipePath(recipe) }, recipe.title)))),
  ];
}

function recipeView(recipe) {
  document.title = `${recipe.title} · Recipes`;
  const heading = recipe.link
    ? h("a", { href: recipe.link, rel: "noopener noreferrer" }, recipe.title)
    : recipe.title;

  return [
    h("article", { class: "recipe" },
      h("h1", { tabindex: "-1" }, heading),
      recipe.servings ? h("p", { class: "servings" }, recipe.servings) : null,
      recipe.image_url ? h("img", { class: "photo", src: recipe.image_url, alt: "", decoding: "async" }) : null,
      h("div", { class: "recipe-body" },
        h("section", { class: "ingredients", "aria-labelledby": "ingredients-heading" },
          h("h2", { id: "ingredients-heading" }, "Ingredients"),
          h("ul", {}, (recipe.ingredients || []).map((item) => h("li", {}, item)))),
        h("section", { class: "preparation", "aria-labelledby": "preparation-heading" },
          h("h2", { id: "preparation-heading" }, "Preparation"),
          h("ol", {}, (recipe.preparation_steps || []).map((step) => h("li", {}, step)))))),
  ];
}

function notFoundView() {
  document.title = "Recipe not found · Recipes";
  return [h("h1", { tabindex: "-1" }, "Recipe not found"), h("p", {}, h("a", { href: "/recipes" }, "Back to all recipes"))];
}

function errorView(error) {
  document.title = "Recipes";
  return [h("h1", { tabindex: "-1" }, "Couldn’t load recipes"), h("p", { role: "alert" }, error.message)];
}

function passwordView() {
  document.title = "Recipes";
  const input = h("input", {
    id: "password", name: "password", type: "password", autocomplete: "current-password",
    enterkeyhint: "done", required: true,
  });
  const error = h("p", { class: "form-error", role: "alert" });
  const showPassword = h("input", { id: "show-password", type: "checkbox" });
  showPassword.addEventListener("change", () => {
    input.type = showPassword.checked ? "text" : "password";
  });

  const form = h("form", { class: "password-form" },
    h("label", { for: "password" }, "Password"),
    input,
    h("div", { class: "show-password" }, showPassword, h("label", { for: "show-password" }, "Show password")),
    error,
    h("button", { type: "submit" }, "Unlock"));

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    if (passwordMatches(input.value)) {
      unlock();
      render();
    } else {
      error.textContent = "That password isn’t right. Try again.";
      input.select();
    }
  });

  return [h("h1", { tabindex: "-1" }, "Recipes"), h("p", {}, "Enter the password to see the recipes."), form];
}

async function render({ focus = true } = {}) {
  recipeNav.hidden = !unlocked;
  if (!unlocked) {
    app.replaceChildren(...passwordView());
    app.querySelector("#password").focus();
    return;
  }

  const route = routeFor(location.pathname);
  let content;
  try {
    const recipes = await loadRecipes();
    const index = route.name === "show" ? recipes.findIndex((r) => String(r.id) === route.id) : -1;
    updateNav(route, recipes, index);
    if (route.name === "list") content = listView(recipes);
    else content = index >= 0 ? recipeView(recipes[index]) : notFoundView();
  } catch (error) {
    updateNav({ name: "error" }, [], -1);
    content = errorView(error);
  }

  const update = () => app.replaceChildren(...content);
  if (document.startViewTransition && focus) await document.startViewTransition(update).updateCallbackDone;
  else update();

  // Move focus to the new heading so keyboard and screen reader users land on the new view.
  if (focus) app.querySelector("h1")?.focus({ preventScroll: true });
}

function navigate(path) {
  if (path === location.pathname) return;
  history.pushState(null, "", path);
  window.scrollTo(0, 0);
  render();
}

// Handle in-app links without a full page load; let modified clicks and external links behave normally.
document.addEventListener("click", (event) => {
  if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  const link = event.target.closest("a[href]");
  if (!link || link.target || link.origin !== location.origin) return;
  if (!/^\/(recipes(\/|$)|$)/.test(link.pathname)) return;
  event.preventDefault();
  navigate(link.pathname);
});

document.querySelector('[data-action="random"]').addEventListener("click", async () => {
  try {
    const recipes = await loadRecipes();
    if (recipes.length === 0) return;
    const current = routeFor(location.pathname).id;
    const choices = recipes.length > 1 ? recipes.filter((r) => String(r.id) !== current) : recipes;
    navigate(recipePath(choices[Math.floor(Math.random() * choices.length)]));
  } catch {
    render();
  }
});

window.addEventListener("popstate", () => render());

render({ focus: false });
