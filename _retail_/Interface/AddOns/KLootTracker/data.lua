local AddonName = "KLootTracker"
local KLT = LibStub("AceAddon-3.0"):GetAddon(AddonName)

--Addon
KLT.addonVer = "6.3.1"
KLT.Prefix = "KLT "

-- Local
KLT.playerName = UnitName("player");
KLT.startTrack = false
KLT.fItemTypeAndSubType = ""
KLT.fAwardedState = ""
KLT.fToShow = 10
KLT.masterLooter = ""
KLT.encounterName = ""
KLT.LootMethod = ""
KLT.DontShowAgain = false
KLT.InstanceIdGui = nil
KLT.InstanceMap = {
    ["id"] = nil,
    ["name"] = "",
    ["diff_id"] = 1
}
KLT.inf = {
    ["state"] = false,
    ["content"] = "",
}

--FILTERS UI
KLT.ItemTypeSelect = "All"
KLT.ReceiverSelect = "All"

--FilterList
KLT.ItemSubTypeList = {
    ["All"] = "All",
    ["Miscellaneous"] = "Miscellaneous",
    ["Cloth"] = "Cloth",
    ["Leather"] = "Leather",
    ["Mail"] = "Mail",
    ["Plate"] = "Plate",
    ["Shields"] = "Shields",
    ["Librams"] = "Librams",
    ["Totems"] = "Totems",
    ["Idols"] = "Idols",
    ["Sigils"] = "Sigils",
    ["Relic"] = "Relic",
    ["Weapon"] = "Weapons",
    ["Quest"] = "Quest",
    ["Junk"] = "Tokens",
    ["Consumable"] = "Fragment"
}

KLT.BindTypes = {
    [0] = false, --LE_ITEM_BIND_NONE
    [1] = true, --LE_ITEM_BIND_ON_ACQUIRE
    [2] = false, --LE_ITEM_BIND_ON_EQUIP
    [3] = false, --LE_ITEM_BIND_ON_USE
    [4] = false, --LE_ITEM_BIND_QUEST
}

--Award state
KLT.ReceiverList = {
    ["All"] = "All",
    [false] = "Not Awarded",
    [true] = "Awarded",
    [KLT.playerName] = "|cff33ff00"..KLT.playerName.."|r"
}

--IGNORE&PASS Item Type
KLT.Ignore = {
    "Trade Goods",
    "Projectile",
    "Gem",
    "Reagent",
    "Item Enhancement",
    "Recipe",
    "Quiver",
    "Consumable",
    "Tradeskill",
    "Money",
}

KLT.Exception = {
    [45038] = true,
    [22726] = true
}

--Patch Boss id&name
KLT.BossNameById = {
    [734] = "Malygos",
    [736] = "Tenebron",
    [738] = "Shadron",
    [740] = "Vesperon",
    [742] = "Sartharion",
    [1107] = "Anub'Rekhan",
    [1108] = "Gluth",
    [1109] = "Gothik the Harvester",
    [1110] = "Grand Widow Faerlina",
    [1111] = "Grobbulus",
    [1112] = "Heigan the Unclean",
    [1113] = "Instructor Razuvious",
    [1114] = "Kel'Thuzad",
    [1115] = "Loatheb",
    [1116] = "Maexxna",
    [1117] = "Noth the Plaguebringer",
    [1118] = "Patchwerk",
    [1119] = "Sapphiron",
    [1120] = "Thaddius",
    [1121] = "The Four Horsemen",
    [610] = "Razorgore the Untamed",
    [611] = "Vaelastrasz the Corrupt",
    [612] = "Broodlord Lashlayer",
    [613] = "Firemaw",
    [614] = "Ebonroc",
    [615] = "Flamegor",
    [616] = "Chromaggus",
    [617] = "Nefarian",
    [663] = "Lucifron",
    [664] = "Magmadar",
    [665] = "Gehennas",
    [666] = "Garr",
    [667] = "Shazzrah",
    [668] = "Baron Geddon",
    [669] = "Sulfuron Harbinger",
    [670] = "Golemagg the Incinerator",
    [671] = "Majordomo Executus",
    [672] = "Ragnaros",
    [709] = "The Prophet Skeram",
    [710] = "Silithid Royalty",
    [711] = "Battleguard Sartura",
    [712] = "Fankriss the Unyielding",
    [713] = "Viscidus",
    [714] = "Princess Huhuran",
    [715] = "Twin Emperors",
    [716] = "Ouro",
    [717] = "C'thun",
    [718] = "Kurinnaxx",
    [719] = "General Rajaxx",
    [720] = "Moam",
    [721] = "Buru the Gorger",
    [722] = "Ayamiss the Hunter",
    [723] = "Ossirian the Unscarred",
    [784] = "High Priest Venoxis",
    [785] = "High Priestess Jeklik",
    [786] = "High Priestess Mar'li",
    [787] = "Bloodlord Mandokir",
    [788] = "Edge of Madness",
    [789] = "High Priest Thekal",
    [790] = "Gahz'ranka",
    [791] = "High Priestess Arlokk",
    [792] = "Jin'do the Hexxer",
    [793] = "Hakkar",
    [1084] = "Onyxia",
    [227] = "High Interrogator Gerstahn",
    [228] = "Lord Roccor",
    [229] = "Houndmaster Grebmar",
    [230] = "Ring of Law",
    [231] = "Pyromancer Loregrain",
    [232] = "Lord Incendius",
    [233] = "Warder Stilgiss",
    [234] = "Fineous Darkvire",
    [235] = "Bael'Gar",
    [236] = "General Angerforge",
    [237] = "Golem Lord Argelmach",
    [238] = "Hurley Blackbreath",
    [239] = "Phalanx",
    [240] = "Ribbly Screwspigot",
    [241] = "Plugger Spazzring",
    [242] = "Ambassador Flamelash",
    [243] = "The Seven",
    [244] = "Magmus",
    [267] = "Highlord Omokk",
    [268] = "Shadow Hunter Vosh'gajin",
    [269] = "War Master Voone",
    [270] = "Mother Smolderweb",
    [271] = "Urok Doomhowl",
    [272] = "Quartermaster Zigris",
    [273] = "Gizrul the Slavener",
    [274] = "Halycon",
    [275] = "Overlord Wyrmthalak",
    [343] = "Zevrim Thornhoof",
    [344] = "Hydrospawn",
    [345] = "Lethtendris",
    [346] = "Alzzin the Wildshaper",
    [347] = "Illyanna Ravenoak",
    [348] = "Magister Kalendris",
    [349] = "Immol'thar",
    [350] = "Tendris Warpwood",
    [361] = "Prince Tortheldrin",
    [362] = "Guard Mol'dar",
    [363] = "Stomper Kreeg",
    [364] = "Guard Fengus",
    [365] = "Guard Slip'kik",
    [366] = "Captain Kromcrush",
    [367] = "Cho'Rush the Observer",
    [368] = "King Gordok",
    [378] = "Viscous Fallout",
    [379] = "Grubbis",
    [380] = "Electrocutioner 6000",
    [381] = "Crowd Pummeler 9-60",
    [382] = "Mekgineer Thermaplugg",
    [422] = "Noxxion",
    [423] = "Razorlash",
    [424] = "Lord Vyletongue",
    [425] = "Celebras the Cursed",
    [426] = "Landslide",
    [427] = "Tinkerer Gizlock",
    [428] = "Rotgrip",
    [429] = "Princess Theradras",
    [438] = "Roogug",
    [444] = "Interrogator Vishas",
    [446] = "Houndmaster Loksey",
    [447] = "Arcanist Doan",
    [448] = "Herod",
    [449] = "High Inquisitor Fairbanks",
    [450] = "High Inquisitor Whitemane",
    [472] = "The Unforgiven",
    [473] = "Hearthsinger Forresten",
    [474] = "Timmy the Cruel",
    [475] = "Willey Hopebreaker",
    [476] = "Commander Malor",
    [477] = "Instructor Galford",
    [478] = "Balnazzar",
    [479] = "Baroness Anastari",
    [480] = "Nerub'enkan",
    [481] = "Maleki the Pallid",
    [482] = "Magistrate Barthilas",
    [483] = "Ramstein the Gorger",
    [484] = "Lord Aurius Rivendare",
    [486] = "Dreamscythe",
    [487] = "Weaver",
    [488] = "Jammal'an the Prophet",
    [490] = "Morphaz",
    [491] = "Hazzas",
    [492] = "Avatar of Hakkar",
    [493] = "Shade of Eranikus",
    [547] = "Revelosh",
    [548] = "The Lost Dwarves",
    [549] = "Ironaya",
    [551] = "Ancient Stone Keeper",
    [552] = "Galgann Firehammer",
    [553] = "Grimlok",
    [554] = "Archaedas",
    [585] = "Lady Anacondra",
    [586] = "Lord Cobrahn",
    [587] = "Kresh",
    [588] = "Lord Pythas",
    [589] = "Skum",
    [590] = "Lord Serpentis",
    [591] = "Verdan the Everliving",
    [592] = "Mutanus the Devourer",
    [593] = "Hydromancer Velratha",
    [594] = "Ghaz'rilla",
    [595] = "Antu'sul",
    [596] = "Theka the Martyr",
    [597] = "Witch Doctor Zum'rah",
    [598] = "Nekrum Gutchewer",
    [599] = "Shadowpriest Sezz'ziz",
    [600] = "Chief Ukorz Sandscalp",
    [161] = "Rhahk'zor",
    [162] = "Sneed",
    [163] = "Gilnid",
    [164] = "Mr. Smite",
    [165] = "Cookie",
    [166] = "Captain Greenskin",
    [167] = "Edwin VanCleef",
    [219] = "Ghamoo-ra",
    [220] = "Lady Sarevess",
    [221] = "Gelihast",
    [222] = "Lorgus Jett",
    [224] = "Old Serra'kis",
    [225] = "Twilight Lord Kelris",
    [226] = "Aku'mai",
    [245] = "Emperor Dagran Thaurissan",
    [250] = "Yor",
    [276] = "Pyroguard Emberseer",
    [277] = "Solakar Flamewreath",
    [278] = "Warchief Rend Blackhand",
    [279] = "The Beast",
    [280] = "General Drakkisath",
    [430] = "Oggleflint",
    [431] = "Taragaman the Hungerer",
    [432] = "Jergosh the Invoker",
    [433] = "Bazzalan",
    [434] = "Tuten'kash",
    [435] = "Mordresh Fire Eye",
    [436] = "Glutton",
    [437] = "Amnennar the Coldbringer",
    [439] = "Aggem Thorncurse",
    [440] = "Death Speaker Jargba",
    [441] = "Overlord Ramtusk",
    [443] = "Charlga Razorflank",
    [445] = "Bloodmage Thalnos",
    [464] = "Rethilgore",
    [465] = "Razorclaw the Butcher",
    [466] = "Baron Silverlaine",
    [467] = "Commander Springvale",
    [468] = "Odo the Blindwatcher",
    [469] = "Fenrus the Devourer",
    [470] = "Wolf Master Nandos",
    [471] = "Archmage Arugal",
    [601] = "High Warlord Naj'entus",
    [602] = "Supremus",
    [603] = "Shade of Akama",
    [604] = "Teron Gorefiend",
    [605] = "Gurtogg Bloodboil",
    [606] = "Reliquary of Souls",
    [607] = "Mother Shahraz",
    [608] = "The Illidari Council",
    [609] = "Illidan Stormrage",
    [618] = "Rage Winterchill",
    [619] = "Anetheron",
    [620] = "Kaz'rogal",
    [621] = "Azgalor",
    [622] = "Archimonde",
    [623] = "Hydross the Unstable",
    [624] = "The Lurker Below",
    [625] = "Leotheras the Blind",
    [626] = "Fathom-Lord Karathress",
    [627] = "Morogrim Tidewalker",
    [628] = "Lady Vashj",
    [649] = "High King Maulgar",
    [650] = "Gruul the Dragonkiller",
    [651] = "Magtheridon",
    [652] = "Attumen the Huntsman",
    [653] = "Moroes",
    [654] = "Maiden of Virtue",
    [655] = "Opera Hall",
    [656] = "The Curator",
    [657] = "Terestian Illhoof",
    [658] = "Shade of Aran",
    [659] = "Netherspite",
    [660] = "Chess Event",
    [661] = "Prince Malchezaar",
    [662] = "Nightbane",
    [724] = "Kalecgos",
    [725] = "Brutallus",
    [726] = "Felmyst",
    [727] = "Eredar Twins",
    [728] = "M'uru",
    [729] = "Kil'jaeden",
    [730] = "Al'ar",
    [731] = "Void Reaver",
    [732] = "High Astromancer Solarian",
    [733] = "Kael'thas Sunstrider",
    [883] = "Agathelos the Raging",
    [1189] = "Akil'zon",
    [1190] = "Nalorakk",
    [1191] = "Jan'alai",
    [1192] = "Halazzi",
    [1193] = "Hex Lord Malacrass",
    [1194] = "Zul'jin",
    [1889] = "Exarch Maladaar",
    [1890] = "Shirrak the Dead Watcher",
    [1891] = "Omor the Unscarred",
    [1892] = "Vazruden the Herald",
    [1893] = "Watchkeeper Gargolmar",
    [1894] = "Kael'thas Sunstrider",
    [1895] = "Priestess Delrissa",
    [1897] = "Selin Fireheart",
    [1898] = "Vexallus",
    [1899] = "Nexus-Prince Shaffar",
    [1900] = "Pandemonius",
    [1901] = "Tavarok",
    [1902] = "Talon King Ikiss",
    [1903] = "Darkweaver Syth",
    [1904] = "Anzu",
    [1905] = "Lieutenant Drake",
    [1906] = "Epoch Hunter",
    [1907] = "Captain Skarloc",
    [1908] = "Ambassador Hellmaw",
    [1909] = "Blackheart the Inciter",
    [1910] = "Murmur",
    [1911] = "Grandmaster Vorpil",
    [1913] = "Dalliah the Doomsayer",
    [1914] = "Harbinger Skyriss",
    [1915] = "Wrath-Scryer Soccothrates",
    [1916] = "Zereketh the Unbound",
    [1919] = "Aeonus",
    [1920] = "Chrono Lord Deja",
    [1921] = "Temporus",
    [1922] = "The Maker",
    [1923] = "Keli'dan the Breaker",
    [1924] = "Broggok",
    [1925] = "Commander Sarannis",
    [1926] = "High Botanist Freywinn",
    [1927] = "Laj",
    [1928] = "Thorngrin the Tender",
    [1929] = "Warp Splinter",
    [1930] = "Nethermancer Sepethrea",
    [1931] = "Pathaleon the Calculator",
    [1932] = "Mechano-Lord Capacitus",
    [1933] = "Gatewatcher Gyro-Kill",
    [1934] = "Gatewatcher Iron-Hand",
    [1935] = "Blood Guard Porung",
    [1936] = "Grand Warlock Nethekurse",
    [1937] = "Warbringer O'mrogg",
    [1938] = "Warchief Kargath Bladefist",
    [1939] = "Mennu the Betrayer",
    [1940] = "Quagmirran",
    [1941] = "Rokmar the Crackler",
    [1942] = "Hydromancer Thespia",
    [1943] = "Mekgineer Steamrigger",
    [1944] = "Warlord Kalithresh",
    [1945] = "Ghaz'an",
    [1946] = "Hungarfen",
    [1947] = "Swamplord Musel'ek",
    [1948] = "The Black Stalker",
    [212] = "Elder Nadox",
    [213] = "Prince Taldaram",
    [214] = "Jedoga Shadowseeker",
    [215] = "Herald Volazj",
    [216] = "Krik'thir the Gatewatcher",
    [217] = "Hadronox",
    [218] = "Anub'arak",
    [293] = "Meathook",
    [294] = "Salram the Fleshcrafter",
    [295] = "Chrono-Lord Epoch",
    [296] = "Mal'ganis",
    [334] = "Grand Champions",
    [338] = "Argent Champion",
    [340] = "The Black Knight",
    [369] = "Trollgore",
    [371] = "Novos the Summoner",
    [373] = "King Dred",
    [375] = "The Prophet Tharon'ja",
    [383] = "Slad'ran",
    [385] = "Drakkari Colossus",
    [387] = "Moorabi",
    [390] = "Gal'darah",
    [519] = "Frozen Commander",
    [520] = "Grand Magus Telestra",
    [522] = "Anomalus",
    [524] = "Ormorok the Tree-Shaper",
    [526] = "Keristrasza",
    [528] = "Drakos the Interrogator",
    [530] = "Varos Cloudstrider",
    [532] = "Mage-Lord Urom",
    [534] = "Ley-Guardian Eregos",
    [541] = "First Prisoner",
    [543] = "Second Prisoner",
    [545] = "Cyanigosa",
    [555] = "General Bjarngrim",
    [557] = "Volkhan",
    [559] = "Ionar",
    [561] = "Loken",
    [563] = "Krystallus",
    [565] = "Maiden of Grief",
    [567] = "Tribunal of Ages",
    [569] = "Sjonnir the Ironshaper",
    [571] = "Prince Keleseth",
    [573] = "Skarvold & Dalronn",
    [575] = "Ingvar the Plunderer",
    [577] = "Svala Sorrowgrave",
    [579] = "Gortok Palehoof",
    [581] = "Skadi the Ruthless",
    [583] = "King Ymiron",
    [629] = "Northrend Beasts",
    [633] = "Lord Jaraxxus",
    [637] = "Faction Champions",
    [641] = "Val'kyr Twins",
    [645] = "Anub'arak",
    [744] = "Flame Leviathan",
    [745] = "Ignis the Furnace Master",
    [746] = "Razorscale",
    [747] = "XT-002 Deconstructor",
    [748] = "The Iron Council",
    [749] = "Kologarn",
    [750] = "Auriaya",
    [751] = "Hodir",
    [752] = "Thorim",
    [753] = "Freya",
    [754] = "Mimiron",
    [755] = "General Vezax",
    [756] = "Yogg-Saron",
    [757] = "Algalon the Observer",
    [772] = "Archavon the Stone Watcher",
    [774] = "Emalon the Storm Watcher",
    [776] = "Koralon the Flame Watcher",
    [829] = "Bronjahm",
    [831] = "Devourer of Souls",
    [833] = "Forgemaster Garfrost",
    [835] = "Krick",
    [837] = "Overlrod Tyrannus",
    [839] = "Marwyn",
    [841] = "Falric",
    [843] = "Escaped from Arthas",
    [845] = "Lord Marrowgar",
    [846] = "Lady Deathwhisper",
    [847] = "Icecrown Gunship Battle",
    [848] = "Deathbringer Saurfang",
    [849] = "Festergut",
    [850] = "Rotface",
    [851] = "Professor Putricide",
    [852] = "Blood Council",
    [853] = "Queen Lana'thel",
    [854] = "Valithria Dreamwalker",
    [855] = "Sindragosa",
    [856] = "The Lich King",
    [885] = "Toravon the Ice Watcher",
    [887] = "Halion",
    [890] = "Baltharus the Warborn",
    [891] = "Saviana Ragefire",
    [893] = "General Zarithrian",
    [1966] = "Prince Taldaram",
    [1968] = "Herald Volazj",
    [1969] = "Elder Nadox",
    [1973] = "Anub'arak",
    [1974] = "Trollgore",
    [1975] = "The Prophet Tharon'ja",
    [1977] = "King Dred",
    [1978] = "Slad'ran",
    [1980] = "Moorabi",
    [1981] = "Gal'darah",
    [1983] = "Drakkari Colossus",
    [1984] = "Ionar",
    [1985] = "Volkhan",
    [1986] = "Loken",
    [1987] = "General Bjarngrim",
    [1988] = "Eck the Ferocious",
    [1989] = "Amanitar",
    [1994] = "Krystallus",
    [1996] = "Maiden of Grief",
    [1998] = "Sjonnir the Ironshaper",
    [2002] = "Meathook",
    [2003] = "Chrono-Lord Epoch",
    [2004] = "Salram the Fleshcrafter",
    [2005] = "Mal'ganis",
    [2009] = "Anomalus",
    [2010] = "Grand Magus Telestra",
    [2011] = "Keristrasza",
    [2012] = "Ormorok the Tree-Shaper",
    [2013] = "Ley-Guardian Eregos",
    [2014] = "Mage-Lord Urom",
    [2016] = "Drakos the Interrogator",
    [2024] = "Skarvold & Dalronn",
    [2026] = "Prince Keleseth",
    [2027] = "Gortok Palehoof",
    [2028] = "King Ymiron",
    [2029] = "Skadi the Ruthless",
    [2030] = "Svala Sorrowgrave",
    [2658] = "Erekem",
    [2659] = "Moragg",
    [2660] = "Ichoron",
    [2661] = "Xevozz",
    [2662] = "Lavanthor",
    [2663] = "Zuramat",
}

--Patch ZoneIgnore
KLT.Zones = {
    [0] = "Eastern Kingdoms",
    [1] = "Kalimdor",
    [530] = "Outland",
    [571] = "Northrend",
    [646] = "Deepholm",
    [730] = "Maelstrom Zone",
    [732] = "Tol Barad",
    [860] = "The Wandering Isle",
    [870] = "Pandaria",
    [1064] = "Isle of Thunder",
    [1116] = "Draenor",
    [1191] = "Ashran",
    [1464] = "Tanaan Jungle",
    [1220] = "Broken Isles",
    [1669] = "Argus",
    [1642] = "Zandalar",
    [1643] = "Kul Tiras",
    [1718] = "Nazjatar",
    [2222] = "The Shadowlands",
    [2374] = "Zereth Mortis",
    [2444] = "Dragon Isles",
}

-- TrashItems
KLT.TrashItems = {
    --DRAGON ->
    -- RAIDS --
    [2522] = {
        [201992] = true,
        [202003] = true,
        [202007] = true,
        [202004] = true,
        [202008] = true,
        [202005] = true,
        [202009] = true,
        [202006] = true,
        [202010] = true,
    },--Vault of the Incarnates
    -- DUNGEONS --
    [2451] = nil,--Uldaman: Legacy of Tyr
    [2515] = nil,--The Azure Vault
    [2516] = nil,--The Nokhud Offensive
    [2519] = nil,--Neltharus
    [2520] = nil,--Brackenhide Hollow
    [2521] = nil,--Ruby Life Pools
    [2526] = nil,--Algeth'ar Academy
    [2527] = nil,--Halls of Infusion

    --WRATH ->
    -- RAIDS --
    -- The Obsidian Sanctum 10/25
    [615] = nil,
    -- The Eye of Eternity 10/25
    [616] = nil,
    -- Vault of Archavon 10/25
    [624] = nil,
    -- Naxxramas 10/25
    [533] = {
        [39427] = true,
        [39467] = true,
        [39468] = true,
        [39470] = true,
        [39472] = true,
        [39473] = true,
        [40406] = true,
        [40407] = true,
        [40408] = true,
        [40409] = true,
        [40410] = true,
        [40412] = true,
        [40414] = true,
    },
    -- Ulduar 10/25
    [603] = {
        [45547] = true,
        [45538] = true,
        [45539] = true,
        [45540] = true,
        [45541] = true,
        [45542] = true,
        [45543] = true,
        [45544] = true,
        [45548] = true,
        [45549] = true,
        [45605] = true,
        [46339] = true,
        [46340] = true,
        [46341] = true,
        [46342] = true,
        [46343] = true,
        [46344] = true,
        [46345] = true,
        [46346] = true,
        [46347] = true,
        [46350] = true,
        [46351] = true,
    },
    -- Icecrown Citadel 10/25
    [631] = nil,
    -- Trial of the Crusader 10/25
    [649] = nil,
    -- The Ruby Sanctum 10/25
    [724] = nil,
    -- Onyxia's Lair 10/25
    [249] = nil,

    -- DUNGEONS --
    -- Utgarde Keep
    [574] = {
        [35580] = true,
        [35579] = true,
        [37197] = true,
        [37196] = true,
    },
    -- Utgarde Pinnacle
    [575] = {
        [37070] = true,
        [37069] = true,
        [37068] = true,
        [37410] = true,
        [37587] = true,
        [37590] = true,
    },
    -- Drak'Tharon Keep
    [600] = {
        [35641] = true,
        [35640] = true,
        [35639] = true,
        [37799] = true,
        [37800] = true,
        [37801] = true,
    },
    -- Gundrak
    [604] = {
        [37646] = true,
        [35594] = true,
        [35593] = true,
        [37647] = true,
        [37646] = true,
        [37648] = true,
    },
    -- The Nexus
    [576] = nil,
    -- The Oculus
    [578] = {
        [36976] = true,
        [36978] = true,
        [36977] = true,
        [37364] = true,
        [37290] = true,
        [37366] = true,
        [37365] = true,
    },
    -- 	Ahn'kahet: The Old Kingdom
    [619] = {
        [35616] = true,
        [35615] = true,
        [37624] = true,
        [37625] = true,
    },
    -- Azjol-Nerub
    [601] = {
        [35666] = true,
        [35664] = true,
        [35665] = true,
        [37624] = true,
        [37243] = true,
        [37625] = true,
    },
    -- 	Halls of Lightning
    [602] = {
        [36997] = true,
        [37000] = true,
        [36999] = true,
        [37856] = true,
        [37858] = true,
        [37857] = true,
    },
    -- Halls of Stone
    [599] = {
        [35681] = true,
        [35683] = true,
        [35682] = true,
        [37673] = true,
        [37672] = true,
        [37671] = true,
    },
    -- The Violet Hold
    [608] = {
        [35652] = true,
        [35654] = true,
        [35653] = true,
        [37889] = true,
        [35652] = true,
        [35654] = true,
        [37890] = true,
        [35653] = true,
        [37891] = true,
    },
    -- The Culling of Stratholme
    [595] = {
        [37117] = true,
        [37770] = true,
        [37780] = true,
        [37116] = true,
        [37115] = true,
    },
    -- Halls of Reflection
    [668] = {
        [49852] = true,
        [49854] = true,
        [49855] = true,
        [49853] = true,
        [50379] = true,
        [50319] = true,
        [50315] = true,
        [50050] = true,
        [50051] = true,
        [50052] = true,
        [50318] = true,
    },
    -- 	The Forge of Souls
    [632] = {
        [50379] = true,
        [50319] = true,
        [50315] = true,
        [50318] = true,
    },
    -- Trial of the Champion
    [650] = nil,
    -- Pit of Saron
    [658] = {
        [49852] = true,
        [49854] = true,
        [49855] = true,
        [49853] = true,
        [50379] = true,
        [50319] = true,
        [50315] = true,
        [50050] = true,
        [50051] = true,
        [50052] = true,
        [50318] = true,
    },

    --TBC ->   
    -- RAIDS --
    [532] = nil, --Karazhan
    [534] = nil, --Hyjal Summit
    [544] = nil, --Magtheridon's Lair
    [548] = nil, --Serpentshrine Cavern
    [550] = nil, --Tempest Keep
    [564] = nil, --Black Temple
    [565] = nil, --Gruul's Lair
    [580] = nil, --Sunwell Plateau
    -- DUNGEONS --
    [269] =	nil, --The Black Morass
    [540] =	nil, --The Shattered Halls
    [542] =	nil, --The Blood Furnace
    [543] =	nil, --Hellfire Ramparts
    [545] =	nil, --The Steamvault
    [546] =	nil, --The Underbog
    [547] =	nil, --The Slave Pens
    [552] =	nil, --The Arcatraz
    [553] =	nil, --The Botanica
    [554] =	nil, --The Mechanar
    [555] =	nil, --Shadow Labyrinth
    [556] =	nil, --Sethekk Halls
    [557] =	nil, --Mana-Tombs
    [558] =	nil, --Auchenai Crypts
    [560] =	nil, --Old Hillsbrad Foothills
    [585] =	nil, --Magisters' Terrace
    --CLASSIC ->
    -- RAIDS --
     [409] = nil, --Molten Core
     [469] = nil, --Blackwing Lair
     [509] = nil, --Ruins of Ahn'Qiraj
     [531] = nil, --Temple of Ahn'Qiraj
     -- DUNGEONS --
      [33] = nil, --Shadowfang Keep
      [34] = nil, --The Stockade
      [36] = nil, --The Deadmines
      [43] = nil, --Wailing Caverns
      [47] = nil, --Razorfen Kraul
      [48] = nil, --Blackfathom Deeps
      [70] = nil, --Uldaman
      [90] = nil, --Gnomeregan
     [109] = nil, --The Temple of Atal'Hakkar
     [129] = nil, --Razorfen Downs
     [209] = nil, --Zul'Farrak
     [229] = nil, --Blackrock Spire
     [230] = nil, --Blackrock Depths
     [329] = nil, --Stratholme
     [349] = nil, --Maraudon
     [389] = nil, --Ragefire Chasm
     [429] = nil, --Dire Maul
    [1001] = nil, --Scarlet Halls
    [1004] = nil, --Scarlet Monastery
    [1007] = nil, --Scholomance
}

--INFO------------------------------------------------------------------------------------------------------------------
KLT.ML_Disabled = "If LootMethod is Master and ML dont use this Addon, then collect item on receive."

KLT.info = ""..
        "|cff00ccffAddon info:|R \n"..
        "KLootTracker is used to collect items in the current raid or dungeon. You can delete saved items at the end of"..
        " day or after each raid&dungeon, it's up to you.\n\n"..
        "|cff00ff00Table:|R \n"..
        "In the table,you can (filter the item type),(filter if the item was received by someone) and see (the time for trade)."..
        " You can delete the table in InterfaceOptions or every time you enter the instance.\n\n"..
        "|cff00ff00Dungeon/Raid item collection & Award:|R \n"..
        "|cffADFF2FFFA -|R saves items by receiving (save receiver's player name) \n"..
        "|cffADFF2FGL -|R saves items when someone wins them (also saves the winner's name) \n"..
        "|cffADFF2FML -|R saves items by raid message (the receiver is only saved when the item is received by someone other"..
        " than ML. The other receivers are saved only after the TradeAward, ML can use itself Award by mouse&keyPress)\n"..
        "If MasterLooter dont use this addon, u can disable ML tracking in addon and you receive items same as with FFA.\n\n"..
        "|cff00ff00Button Change GL->ML:|R\n"..
        "If your raid used GroupLoot or FFA all the time and one player took everything.. and later items will be split "..
        "by ML to players. So when turning ON the loot method (MASTER), Master Looter can clear receivers by this Button. "..
        "And you can use Trade - AwardSystem.\n\n"..
        "|cffff0000Problems:|R\n"..
        "|cffff00001)|R 40 items per table can freeze the game a bit for a few milliseconds, please reduce the number of"..
        " items at the table or turn off AutoRefresh and refresh the table only when you need."

KLT.info_Award ="MasterLooter award: Move the mouse over the item(in - addon, backpack, etc..) & press\n"..
        "(Right) SHIFT + CTRL for itself Award OR (Right) SHIFT + ALT for return Award.\n"..
        "\nIt works with TradeAward ON."