# cmnw-osint

cmnw-osint is a World of Warcraft addon that collects all character names across your realm via combat log events and your current target.

All parsed data is stored in `data` variable at this **%PATH%**:

```
*\World of Warcraft\_retail_\WTF\Account\%account_name%\%realm%\%name%\SavedVariables
```

Format: 

```
["data"] = {
	{
		["guid"] = "Player-1602-0B401026", // character's guid, {name}-{connected_realm}-{guid}
		["class"] = "Разбойница",
		["race"] = "Человек",
		["name"] = "Инициатива", 
		["sex"] = 3, //1 - ?, 2 - male, 3 - female
		["classSlug"] = "ROGUE",
		["raceSlug"] = "Human",
		["timestamp"] = 1587579319.252,
		["realm"] = "Гордунни",
	}, -- [1]
  }
```
