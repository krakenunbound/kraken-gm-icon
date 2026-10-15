--
-- Kraken GM Icon: the GM's chat picture, chosen in Options > GM Icon.
--
-- The choice is kept per computer (GlobalRegistry), so it follows the GM into
-- every campaign and ruleset. The host copies it into the campaign's public
-- options node so players' computers draw the same picture for GM whispers.
--
-- Value format: "" = Fantasy Grounds' own GM icon, "icon:<name>" = a bundled
-- icon, "asset:<asset path>" = an image from the asset browser.
--

ICONS = {
	"kgmi_01_kraken", "kgmi_02_d20", "kgmi_03_dm_screen", "kgmi_04_hooded", "kgmi_05_dragon_eye",
	"kgmi_06_crown", "kgmi_07_quill", "kgmi_08_crystal_ball", "kgmi_09_skull_candle", "kgmi_10_tower",
};
DEFAULT = "icon:kgmi_01_kraken";
FG_DEFAULT = "-";
DB_PATH = "options.KGMI-icon";
GM_ICON = "portrait_gm_token";

local _tBundled = {};
local _fnGetIdentityAsset;

function onInit()
	for _,s in ipairs(KrakenGMIcon.ICONS) do
		_tBundled[s] = true;
	end

	_fnGetIdentityAsset = ChatIdentityManager.getIdentityAsset;
	ChatIdentityManager.getIdentityAsset = KrakenGMIcon.getIdentityAsset;

	KrakenGMIcon.wrapChatFunction("addChatMessage");
	KrakenGMIcon.wrapChatFunction("deliverChatMessage");

	if Session.IsHost then
		OptionsManager.registerButton("option_label_kgmi", "kgmi_select", "");
		AssetWindowManager.setAssetWindowClassData("kgmi_select", {});
	end
end
function onTabletopInit()
	if Session.IsHost then
		KrakenGMIcon.publish();
	end
end

--
-- CHOICE
--

function getChoice()
	if Session.IsHost then
		local s = GlobalRegistry and GlobalRegistry.KrakenGMIcon;
		if type(s) ~= "string" or s == "" then
			return KrakenGMIcon.DEFAULT;
		end
		return s;
	end
	return DB.getValue(KrakenGMIcon.DB_PATH, "");
end
function setChoice(s)
	if not Session.IsHost then
		return;
	end
	if GlobalRegistry then
		GlobalRegistry.KrakenGMIcon = s or KrakenGMIcon.DEFAULT;
	end
	KrakenGMIcon.publish();
end
function publish()
	DB.setValue(KrakenGMIcon.DB_PATH, "string", KrakenGMIcon.getChoice());
end

function setBundled(sIcon)
	if _tBundled[sIcon] then
		KrakenGMIcon.setChoice("icon:" .. sIcon);
	end
end
function setAsset(sAsset)
	if (sAsset or "") ~= "" then
		KrakenGMIcon.setChoice("asset:" .. sAsset);
	end
end
function setFGDefault()
	KrakenGMIcon.setChoice(KrakenGMIcon.FG_DEFAULT);
end

-- Returns "icon", name | "asset", path | nil (Fantasy Grounds' own icon)
function parseChoice(s)
	s = s or "";
	local sIcon = s:match("^icon:(.+)$");
	if sIcon then
		if _tBundled[sIcon] then
			return "icon", sIcon;
		end
		return nil;
	end
	local sAsset = s:match("^asset:(.+)$");
	if sAsset then
		return "asset", sAsset;
	end
	return nil;
end
function getChoiceLabel(s)
	local sKind, sName = KrakenGMIcon.parseChoice(s or KrakenGMIcon.getChoice());
	if sKind == "icon" then
		return Interface.getString((sName:gsub("^kgmi_", "kgmi_name_")));
	elseif sKind == "asset" then
		return (sName:gsub("@.*$", ""):match("([^/]+)$")) or sName;
	end
	return Interface.getString("kgmi_current_default");
end

--
-- CHAT
--

function getGMAsset()
	local sKind, sName = KrakenGMIcon.parseChoice(KrakenGMIcon.getChoice());
	if sKind == "icon" then
		return { type = "icon", name = sName, w = ChatIdentityManager.ASSET_WIDTH, h = ChatIdentityManager.ASSET_HEIGHT, };
	elseif sKind == "asset" then
		return { name = sName, w = ChatIdentityManager.ASSET_WIDTH, h = ChatIdentityManager.ASSET_HEIGHT, };
	end
	return nil;
end
function getIdentityAsset(sIdentity, ...)
	if (sIdentity or "") == "" then
		local tAsset = KrakenGMIcon.getGMAsset();
		if tAsset then
			return tAsset;
		end
	end
	return _fnGetIdentityAsset(sIdentity, ...);
end

-- A few CoreRPG messages (initiative, Syrinscape) name the GM icon directly.
function fixMessage(msg)
	if type(msg) ~= "table" or msg.icon ~= KrakenGMIcon.GM_ICON then
		return;
	end
	local tAsset = KrakenGMIcon.getGMAsset();
	if not tAsset then
		return;
	end
	-- As a sized asset, not msg.icon: a bundled icon is drawn at its full size there.
	msg.icon = nil;
	msg.assets = msg.assets or {};
	table.insert(msg.assets, 1, tAsset);
end
function wrapChatFunction(sName)
	local fn = Comm[sName];
	if type(fn) ~= "function" then
		return;
	end
	pcall(function()
		Comm[sName] = function(msg, ...)
			KrakenGMIcon.fixMessage(msg);
			return fn(msg, ...);
		end;
	end);
end
