-- Practical profession checklists without fabricated Forever recipe tables.
ForeverCompanionProfessionFieldGuide={}
local G=ForeverCompanionProfessionFieldGuide
G.notes={
 Cooking={"Keep fish, meat and vendor ingredients separate in your shopping plan.","Check whether the recipe needs a fire or another cooking requirement.","Match useful meals to your character before spending rare ingredients."},
 ["First Aid"]={"Reserve cloth for the selected bandage or medical supply recipe.","Check current training ranks and recipe access before stocking up.","Compare recipe skill-up colors; a material reserve does not guarantee skill points."},
 Fishing={"Use water where you can reliably catch fish at your current effective skill.","Keep Cooking recipe needs in mind when choosing which catches to save.","Catches per skill point vary; do not treat a stage as a fixed reagent quota."},
 Alchemy={
  "Check whether the recipe consumes a vial as well as herbs.",
  "Reserve scarce herbs for the potion or elixir you actually need.",
  "Compare consumable demand against your personal questing needs.",
 },
 Blacksmithing={
  "Track ore-to-bar conversion separately from the final item recipe.",
  "Check whether a forge or anvil is required before travelling.",
  "Prioritize weapon or armor upgrades only after comparing material cost.",
 },
 Enchanting={
  "Disenchanting permanently consumes eligible gear; inspect value first.",
  "Track dust, essence and shard needs as distinct materials.",
  "Check the intended item slot and enchant restrictions in the client.",
 },
 Engineering={
  "Components may be used by multiple gadgets; reserve shared materials.",
  "Check engineering skill and item-use restrictions before crafting.",
  "Account for vendor-bought components in material planning.",
 },
 Leatherworking={
  "Track raw leather and processed leather as separate inventory lines.",
  "Inspect armor type and level restrictions before crafting gear.",
  "Reserve rare hides until a specific recipe goal is selected.",
 },
 Tailoring={
  "Track cloth, thread and dye separately; vendor items may be required.",
  "Compare bag utility against cloth needed for equipment.",
  "If disenchanting crafted gear, account for uncertain reagent yields.",
 },
 Herbalism={
  "Match gathering routes to your actual gathering skill and safe travel.",
  "Use recipe goals to identify herbs worth saving instead of selling.",
  "Do not assume a node is available without checking the live client.",
 },
 Mining={
  "Separate ore, bars, stone and gems in your material plan.",
  "Check whether smelting is available and where it can be performed.",
  "Choose gathering detours based on travel safety and actual skill.",
 },
 Skinning={
  "Confirm creature eligibility and skill before planning a skinning route.",
  "Distinguish leather, hides and scraps in the inventory plan.",
  "Avoid treating every kill as a guaranteed skinning yield.",
 },
}
function G.Format(name)
 local notes=G.notes[name]
 if not notes then return "PROFESSION FIELD GUIDE: No curated notes available." end
 local lines={"PROFESSION FIELD GUIDE - "..name}
 for i,note in ipairs(notes) do lines[#lines+1]=i..". "..note end
 lines[#lines+1]="Exact recipes, yields and trainer unlocks must be checked in-game."
 return table.concat(lines,"\n")
end
