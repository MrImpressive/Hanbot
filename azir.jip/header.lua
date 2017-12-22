return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "[Insert Name Here] Azir",
  ["moduleName"] = "[Insert_Name_Here]_Azir",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Azir"
  end
}
