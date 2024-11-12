-- Wide AAI Container Graphics Compatibility if wide-aai-containers is enabled
if mods["aai-containers"] and mods["wide-aai-chests"] and settings.startup["wide-aai-chests-enabled-by-default"].value then
    require("prototypes.compatibility.wide-aai-chests.prototypes")
elseif mods["wide-aai-chests"] and settings.startup["wide-aai-chests-enabled"].value  then
    require("prototypes.compatibility.wide-aai-chests.prototypes")
end

-- Loads mod settings from AAI containers if wide-aai-chests is enabled
if mods["aai-containers"] and mods["wide-aai-chests"] then
    if settings.startup["aai-containers-number-icons"].value  then
        if settings.startup["wide-aai-chests-enabled"].value or settings.startup["wide-aai-chests-enabled-by-default"].value then
            require("prototypes.compatibility.aai-containers.number")
        end
    end
end

--Modifies recipe order for AAI containers if enabled
if mods["aai-containers"] then
    require("prototypes.compatibility.aai-containers.recipes")
end
