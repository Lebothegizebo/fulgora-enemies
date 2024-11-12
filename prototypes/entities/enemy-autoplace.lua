local control_name = "fulgoran_enemies"
data.raw["simple-entity"]["fulgoran-ruin-vault"]["autoplace"].probability_expression=0
data:extend(
{
    {
        type = "autoplace-control",
        name = control_name,
        richness = false,
        order = "a",
        category = "enemy",
        can_be_disabled = false
    },
}
)
local function fulgora_enemy_autoplace(params)
return
{
    control = control_name,
    order = params.order,
    force = "enemy",
    probability_expression = params.probability_expression,
    richness_expression = 1
}
end

function fulgora_enemy_spawner_autoplace(probability_expression)
return fulgora_enemy_autoplace{
    probability_expression = probability_expression,
    order = "b[enemy]-a[spawner]"
}
end


	local fulgora = data.raw.planet.fulgora
	fulgora.pollutant_type = "pollution"
	fulgora.map_gen_settings.autoplace_controls[control_name] = {}
    fulgora.map_gen_settings.autoplace_controls[control_name] = {}
