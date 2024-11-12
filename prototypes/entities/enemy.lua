data.extend{
    {
        type = "unit-spawner",
        name = "robot-spawner",
        icon = "__base__/graphics/icons/biter-spawner.png",
        flags = {"placeable-player", "placeable-enemy", "not-repairable"},
        surface = "fulgora",
        max_health = 350,
        order="a",
        subgroup="enemies",
        resistances =
        {
        {
            type = "physical",
            decrease = 2,
            percent = 15
        },
        {
            type = "explosion",
            decrease = 5
            },
        {
            type = "fire",
            decrease = 3,
            percent = 60
        }
        },
        working_sound =
        {
            sound = { filename = "__base__/sound/creatures/spawner.ogg", volume = 0.6},
            max_sounds_per_type = 3
        },
        healing_per_tick = 0.02,
        collision_box = {{-2.2, -2.2}, {2.2, 2.2}},
        map_generator_bounding_box = {{-3.7, -3.2}, {3.7, 3.2}},
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        absorptions_per_second = { pollution = { absolute = 20, proportional = 0.01 } },
        dying_explosion = "biter-spawner-die",
        max_count_of_owned_units = 7,
        max_friends_around_to_spawn = 5,
            picture = 
            {
                filename = "__fulgora_enemies__/graphics/icons/biter-spawner.png",
            },
        result_units = (function()
                        local res = {}
                        res[1] = {"small-biter", {{0.0, 0.3}, {0.6, 0.0}}}
                        if not data.is_demo then
                        -- from evolution_factor 0.3 the weight for medium-biter is linearly rising from 0 to 0.3
                        -- this means for example that when the evolution_factor is 0.45 the probability of spawning
                        -- a small biter is 66% while probability for medium biter is 33%.
                        res[2] = {"medium-biter", {{0.2, 0.0}, {0.6, 0.3}, {0.7, 0.1}}}
                        -- for evolution factor of 1 the spawning probabilities are: small-biter 0%, medium-biter 1/8, big-biter 4/8, behemoth biter 3/8
                        res[3] = {"big-biter", {{0.5, 0.0}, {1.0, 0.4}}}
                        res[4] = {"behemoth-biter", {{0.9, 0.0}, {1.0, 0.3}}}
                        end
                        return res
                        end)(),
        -- With zero evolution the spawn rate is 6 seconds, with max evolution it is 2.5 seconds
        spawning_cooldown = {360, 150},
        spawning_radius = 10,
        spawning_spacing = 3,
        max_spawn_shift = 0,
        max_richness_for_spawn_shift = 100,
        call_for_help_radius = 50,
        }
      }
