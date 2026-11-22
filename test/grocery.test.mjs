import { test } from "node:test";
import assert from "node:assert/strict";
import { groceryList, ingredientKeys, ingredientName, isLabel, storeSection } from "../site/grocery.js";

test("strips amounts, units and notes from the name", () => {
  assert.equal(ingredientName("4 garlic cloves, thinly sliced"), "garlic cloves");
  assert.equal(ingredientName("2 (12- to 18-ounce) packages shelf-stable potato gnocchi"), "shelf-stable potato gnocchi");
  assert.equal(ingredientName("¾ tsp. (4 g) baking soda"), "baking soda");
  assert.equal(ingredientName("2 to 2 ½ pounds boneless pork shoulder, trimmed"), "boneless pork shoulder");
  assert.equal(ingredientName("1 ½ pounds boneless, skinless chicken thighs"), "boneless, skinless chicken thighs");
  assert.equal(ingredientName("1½ tsp. Diamond Crystal or ¾ tsp. Morton kosher salt, plus more"), "kosher salt");
  assert.equal(ingredientName("Grated Parmesan, for serving"), "Grated Parmesan");
});

test("singular and plural units", () => {
  assert.equal(ingredientName("1 box spaghetti"), "spaghetti");
  assert.equal(ingredientName("2 boxes chicken broth"), "chicken broth");
  assert.equal(ingredientName("2 bunches scallions"), "scallions");
  assert.equal(ingredientName("1 large egg"), "large egg");
  assert.equal(ingredientName("14–16 oz. block firm tofu, drained"), "firm tofu");
  assert.equal(ingredientName("4 blocks/12 ounces instant dried ramen noodles, flavor packets discarded"), "instant dried ramen noodles");
  assert.equal(ingredientName("1 cup/240 ml whole milk"), "whole milk");
  assert.equal(ingredientName("1/2 cup minced fresh mint"), "minced fresh mint");
  assert.equal(ingredientName("2 8-oz. cans water chestnuts, drained"), "water chestnuts");
  assert.equal(ingredientName("1 7-oz. bag mung bean sprouts (about 2½ cups)"), "mung bean sprouts");
  assert.equal(ingredientName('1 2" piece ginger, peeled'), "ginger");
  assert.equal(ingredientName('1 1"-piece ginger, peeled, finely grated'), "ginger");
  assert.equal(ingredientName("1 ½ pounds baby bok choy"), "baby bok choy");
  assert.equal(ingredientName("2-3 garlic cloves"), "garlic cloves");
});

test("gives the same key to the same ingredient", () => {
  assert.deepEqual(ingredientKeys("2 tablespoons extra-virgin olive oil"), ["olive oil"]);
  assert.deepEqual(ingredientKeys("5 tablespoons extra virgin olive oil"), ["olive oil"]);
  assert.deepEqual(ingredientKeys("1 garlic clove, finely grated"), ["garlic"]);
  assert.deepEqual(ingredientKeys("Freshly ground black pepper"), ["pepper"]);
  assert.deepEqual(ingredientKeys("2 pints small tomatoes"), ["tomato"]);
  assert.notDeepEqual(ingredientKeys("1 (28-ounce) can diced tomatoes"), ["tomato"]);
  assert.deepEqual(ingredientKeys("½ teaspoon red-pepper flakes"), ["red-pepper flake"]);
  assert.deepEqual(ingredientKeys("1 pound boneless, skinless chicken thighs"), ["boneless skinless chicken thigh"]);
  assert.deepEqual(ingredientKeys("8 bone-in, skin-on chicken thighs"), ["bone-in skin-on chicken thigh"]);
});

test("splits salt and pepper into two items", () => {
  assert.deepEqual(ingredientKeys("Kosher salt and black pepper"), ["salt", "pepper"]);
});

test("skips labels", () => {
  assert.ok(isLabel("For the sauce:"));
  assert.ok(!isLabel("1 cup yogurt"));
});

test("groups lines from several recipes, keeping each as written", () => {
  const gnocchi = { id: "gnocchi", title: "Gnocchi", ingredients: ["For the sauce:", "4 garlic cloves, thinly sliced", "2 tablespoons extra-virgin olive oil", "Salt and pepper"] };
  const fish = { id: "fish", title: "Fish", ingredients: ["1 garlic clove, finely grated", "3 tablespoons olive oil"] };
  const list = groceryList([gnocchi, fish]);

  assert.deepEqual(list.map((group) => group.name), ["Garlic", "Olive oil", "Pepper", "Salt"]);
  assert.equal(groceryList([{ ingredients: ["¼ cup thinly sliced or torn basil leaves (optional)"] }])[0].name, "Basil");
  const garlic = list.find((group) => group.key === "garlic");
  assert.deepEqual(garlic.lines.map(({ text, recipe }) => [text, recipe.id]),
    [["4 garlic cloves, thinly sliced", "gnocchi"], ["1 garlic clove, finely grated", "fish"]]);
});

test("strips a second amount after plus, and keeps modifiers before a comma", () => {
  assert.equal(ingredientName("1 Tbsp. plus 1 tsp. sugar"), "sugar");
  assert.equal(ingredientName("Pinch of ground nutmeg"), "ground nutmeg");
  assert.equal(ingredientName("A small handful of rosemary"), "rosemary");
  assert.equal(ingredientName("1 head of purple cabbage"), "purple cabbage");
  assert.equal(ingredientName("Bunch cilantro"), "cilantro");
  assert.equal(ingredientName("1 Tbsp. plus 1 tsp. Diamond Crystal or 2¼ tsp. Morton kosher salt"), "kosher salt");
  assert.equal(ingredientName("½ cup roasted, salted nuts, coarsely chopped"), "roasted, salted nuts");
  assert.deepEqual(ingredientKeys("2 tablespoons melted and cooled butter (optional)"), ["butter"]);
});

test("sorts items into store sections", () => {
  const section = (line) => storeSection(ingredientKeys(line)[0]);
  assert.equal(section("4 garlic cloves"), "Produce");
  assert.equal(section("1 teaspoon garlic powder"), "Grocery");
  assert.equal(section("1 teaspoon grated fresh ginger"), "Produce");
  assert.equal(section("1 teaspoon ground ginger"), "Grocery");
  assert.equal(section("4 cups chicken broth"), "Grocery");
  assert.equal(section("1 pound boneless, skinless chicken thighs"), "Meat");
  assert.equal(section("4 (6-ounce) fish fillets"), "Meat");
  assert.equal(section("¾ cup unsweetened coconut milk"), "Grocery");
  assert.equal(section("1½ cups whole milk"), "Dairy");
  assert.equal(section("3 large eggs"), "Dairy");
  assert.equal(section("1 (28-ounce) can diced tomatoes"), "Grocery");
  assert.equal(section("2 pints cherry or grape tomatoes"), "Produce");
  assert.equal(section("1 red bell pepper"), "Produce");
  assert.equal(section("½ teaspoon red-pepper flakes"), "Grocery");
  assert.equal(section("1 pound green beans"), "Produce");
  assert.equal(section("1 (15-ounce) can white beans"), "Grocery");
  assert.equal(section("Condiment of choice"), "Other");
});

test("leaves tap water off the list", () => {
  const names = groceryList([{ ingredients: [
    "2 tablespoons water, plus more as needed", "1 cup cold water", "Boiling water", "4 cups ice water",
    "1 cup coconut water", "2 8-oz. cans water chestnuts", "1 onion",
  ] }]).map((g) => g.name);
  assert.deepEqual(names, ["Coconut water", "Onion", "Water chestnuts"]);
});
