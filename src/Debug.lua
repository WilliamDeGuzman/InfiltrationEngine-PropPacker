local Debug = {}

-- Ideally, I don't start spamming debug logs for users of my plugin!

function Debug:debugLogsEnabled()
	local debugAttribute = workspace:GetAttribute("PropPackerDebug")
	if debugAttribute ~= nil then
		return debugAttribute
	else
		return game:GetService("StudioService"):GetUserId() == 183917359 -- me, for debug convenience lol
	end
end
-- short for console log, obviously
function Debug:clog(text)
	if Debug:debugLogsEnabled() then
		print(text) 
	end
end
	
	
return Debug
