-- ============================================================
-- IndonesianWords.luau -- ModuleScript -> ServerStorage/Minigames/SambungKata
-- Loader: memuat chunk IndonesianWords_1 s/d IndonesianWords_10.
-- Kamus Bahasa Indonesia untuk minigame Sambung Kata.
-- ============================================================

local IndonesianWords = {}
local lookup = {}

local DOUBLE_VOWELS = { "aa", "ee", "ii", "oo", "uu" }

local function hasSuspiciousRepeatedLetters(word)
	for _, pair in ipairs(DOUBLE_VOWELS) do
		if word:find(pair, 1, true) then
			return true
		end
	end
	return word:find("hh", 1, true) ~= nil
end

local folder = script.Parent
local NUM_CHUNKS = 10
local totalLoaded = 0

local function addWord(word)
	if type(word) ~= "string" or word == "" then return false end
	local lower = string.lower(word)
	if hasSuspiciousRepeatedLetters(lower) then return false end
	if lookup[lower] then return false end
	lookup[lower] = true
	totalLoaded = totalLoaded + 1
	return true
end

for i = 1, NUM_CHUNKS do
	local chunkName = "IndonesianWords_" .. i
	local chunkModule = folder:FindFirstChild(chunkName)
	if chunkModule then
		local ok, words = pcall(require, chunkModule)
		if ok and type(words) == "table" then
			for _, w in ipairs(words) do
				addWord(w)
			end
		else
			warn("[IndonesianWords] Gagal require chunk " .. i .. ": " .. tostring(words))
		end
	else
		warn("[IndonesianWords] Chunk tidak ditemukan: " .. chunkName)
	end
end

print("[IndonesianWords] Total kata dimuat: " .. totalLoaded)

function IndonesianWords.IsValid(word)
	if not word or word == "" then return false end
	return lookup[string.lower(word)] == true
end

function IndonesianWords.GetRandomWord()
	local keys = {}
	for k in pairs(lookup) do table.insert(keys, k) end
	if #keys == 0 then return "merdeka" end
	return keys[math.random(#keys)]
end

return IndonesianWords
