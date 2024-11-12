-- Migrations
script.on_configuration_changed(function (data)
	for _, force in pairs(game.forces) do
		force.reset_technology_effects()
		print("Migrations complete.")
	end
end)

-- Rotatable chests

---@param bp_filters BlueprintLogisticFilter[]
---@return LogisticFilter[]
local function convert_bp_filters(bp_filters)
	---@type LogisticFilter[]
	local filters = {}

	for _, filter in pairs(bp_filters) do
		filters[filter.index] = {
			value = {
				type = filter.type,
				name = filter.name,
				quality = filter.quality,
				comparator = filter.comparator
			},
			min = filter.count,
			max = filter.max_count,
			minimum_delivery_count = filter.minimum_delivery_count,
			-- Import_from??
		}
	end

	return filters
end

---@param chest_tags ChestTags
---@param requester LuaLogisticPoint
local function repair_logistic(requester, chest_tags)
	requester.remove_section(requester.sections_count) -- Remove starting section
	requester.trash_not_requested = chest_tags.request.trash_not_requested or false

	for _, tag_section in pairs(chest_tags.request.sections) do
		---@type LuaLogisticSection
		local section
		if tag_section.group then
			section = requester.add_section(tag_section.group)--[[@as LuaLogisticSection]]
		else
			section = requester.add_section()--[[@as LuaLogisticSection]]
			section.filters = convert_bp_filters(tag_section.filters or {})
		end
		section.multiplier = tag_section.multiplier or 1
		section.active = tag_section.active ~= false
	end
end

---@type table<string,fun(entity:LuaEntity, chest_tags:ChestTags, tags:Tags)>
local restore_from_bp = {
	["container"] = function (entity, chest_tags, tags)
		if not chest_tags.circuit then return end

		local behavior = entity.get_or_create_control_behavior() --[[@as LuaContainerControlBehavior]]
		behavior.read_contents = chest_tags.circuit.read_contents or false
	end,

	["logistic-container"] = function (entity, chest_tags, tags)
		if chest_tags.circuit then
			local circuit = chest_tags.circuit
			---@cast circuit -?
			local behavior = entity.get_or_create_control_behavior() --[[@as LuaLogisticContainerControlBehavior]]
			if circuit.circuit_condition then
				behavior.circuit_condition = {condition=circuit.circuit_condition}
			end
			if circuit.circuit_condition_enabled then
				behavior.circuit_condition_enabled = circuit.circuit_condition_enabled
			end
			if circuit.circuit_mode_of_operation then
				behavior.circuit_exclusive_mode_of_operation = circuit.circuit_mode_of_operation
			end
			chest_tags.circuit = nil
		end

		if chest_tags.request then
			if chest_tags.request.request_from_buffers then
				entity.request_from_buffers = chest_tags.request.request_from_buffers
			end

			local point = entity.get_logistic_point(defines.logistic_member_index.logistic_container)
			---@cast point LuaLogisticPoint?
			-- Workaround for not being able to affect ghost points
			if not point then
				chest_tags.request.request_from_buffers = nil
				tags.wide_chest = chest_tags
				goto skip_request
			end

			repair_logistic(point, chest_tags)
			chest_tags.request = nil
		end
		::skip_request::

		entity.tags = tags
	end,
}


---@param entity LuaEntity
---@param full_name string
---@param tags Tags
---@param is_ghost boolean
local function chest_built(entity, full_name, tags, is_ghost)
	local entity_name = full_name:sub(11)
	local surface = entity.surface

	local direction = entity.direction % 8 --[[@as int]]
	if direction % 4 ~= 0 then
		error("Entity starting with 'rotatable-' had a non-cardinal direction: "
			..full_name..":\n"..serpent.block(entity)
		)
	end

	if direction == 0 then
		entity_name = "wide-"..entity_name
	else
		entity_name = "tall-"..entity_name
	end

	local chest_tags = tags.wide_chest or {} --[[@as ChestTags]]
	tags.wide_chest = nil

	---@type LuaSurface.create_entity_param
	local create = {
		name = entity_name,
		inner_name = entity_name,
		quality = entity.quality,

		position = entity.position,
		force = entity.force,
		player = entity.last_user,
		create_build_effect_smoke = false,

		bar = chest_tags.bar,
		fast_replace = true,
	}
	chest_tags.bar = nil

	if is_ghost then
		create.name = "entity-ghost"
		create.inner_name = entity_name
		create.tags = tags
	end

	local new_entity = surface.create_entity(create)
	if not new_entity then error("Replacement failed!") end

	if chest_tags then
		local func = restore_from_bp[is_ghost and new_entity.ghost_type or new_entity.type]
		if func then func(new_entity, chest_tags, tags) end
	end
end

local is_beta = settings.startup["enable-wide-containers-beta"].value --[[@as boolean]]

---@alias BuiltEventData
---| EventData.on_built_entity
---| EventData.on_robot_built_entity
---| EventData.on_space_platform_built_entity
---| EventData.script_raised_built
---@param EventData BuiltEventData
local function built(EventData)
	local entity = EventData.entity
	local type, name, tags = entity.type, "", EventData.tags or {}
	local is_ghost = type == "entity-ghost"
	if is_ghost and is_beta then
		type = entity.ghost_type
		name = entity.ghost_name
		tags = entity.tags or {}
	else
		name = entity.name
	end

	if type == "assembling-machine"
	and name:sub(1, 10) == "rotatable-" then
		chest_built(entity, name, tags, is_ghost)
	elseif tags.wide_chest then
		local chest_tags = tags.wide_chest--[[@as ChestTags]]
		local point = entity.get_logistic_point(defines.logistic_member_index.logistic_container)
		if not point then return log("Could not repair tags when reviving the entity") end
		repair_logistic(point, chest_tags)
	end
end

script.on_event(defines.events.on_built_entity, built)
script.on_event(defines.events.on_robot_built_entity, built)
script.on_event(defines.events.script_raised_revive, built)
script.on_event(defines.events.on_space_platform_built_entity, built)

---@class ChestTags
---@field circuit? ChestTags.circuit
---@field bar? uint
---@field request? ChestTags.request_filters

---@class ChestTags.circuit
---@field read_contents? boolean
---@field circuit_condition_enabled? boolean
---@field circuit_condition? CircuitCondition
---@field circuit_mode_of_operation? defines.control_behavior.logistic_container.exclusive_mode defaults to `defines.control_behavior.logistic_container.exclusive_mode.send_contents`

---@class ChestTags.request_filters
---@field request_from_buffers? boolean
---@field trash_not_requested? boolean
---@field sections ChestTags.request_filters.section[]

---@class ChestTags.request_filters.section
---@field index uint
---@field filters? BlueprintLogisticFilter[]
---@field group? string
---@field multiplier? int
---@field active? false

script.on_event(defines.events.on_player_setup_blueprint, function (EventData)
	local blueprint = EventData.stack
	if not blueprint then error() end
	local entities = blueprint.get_blueprint_entities()
	if not entities then error() end

	for _, entity in pairs(entities) do
		local type_str = entity.name:sub(1, 5)
		local type = type_str == "wide-" and 0 or type_str == "tall-" and 4 or nil --[[@as defines.direction?]]
		if type then
			local chest = entity.name:sub(6)
			entity.name = "rotatable-"..chest
			entity.direction = type
			entity.tags = entity.tags or {}
			entity.tags.wide_chest = {
				circuit = entity.control_behavior,
				bar = entity.bar,
				request = entity.request_filters
			}--[[@as ChestTags]]
			entity.control_behavior = nil
			entity.bar = nil
		end
	end

	blueprint.set_blueprint_entities(entities)
end)