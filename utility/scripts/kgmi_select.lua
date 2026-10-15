--
-- Options > GM Icon picker. A choice applies at once; Cancel puts the old one back.
--

local _sLastChoice;

function onInit()
	_sLastChoice = KrakenGMIcon.getChoice();
	super.onInit();
	title.setValue(Interface.getString("kgmi_select_window_title"));
end

function refresh()
	if sub_bundled and sub_bundled.subwindow then
		sub_bundled.subwindow.update();
	end
end

function onActivate(sAsset)
	KrakenGMIcon.setAsset(sAsset);
	refresh();
end
function handleBundled(sIcon)
	KrakenGMIcon.setBundled(sIcon);
	refresh();
end
function handleFGDefault()
	KrakenGMIcon.setFGDefault();
	refresh();
end
function handleOK()
	close();
end
function handleCancel()
	KrakenGMIcon.setChoice(_sLastChoice);
	close();
end
