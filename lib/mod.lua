   -- høstløv

   -- nb_harvest v1.0 - imminent gloom
   -- nb boilerplate v0.1 @sonoCircuit

   local mu = require "musicutil"
   local md = require "core/mods"
   local vx = require "voice"

   local NUM_VOICES = 6 -- should correspond to the numVoices in the sc file.

   local function dont_panic()
      osc.send({ "localhost", 57120 }, "/nb_harvest/panic") 
   end

   local function set_param(key, val)
      osc.send({ "localhost", 57120 }, "/nb_harvest/set_param", {key, val}) 
   end

   local function round_form(param, quant, form) -- param formatting (optional)
      return(util.round(param, quant)..form)
   end

   local function add_nb_harvest_params()
      params:add_group("nb_harvest_group", "HØST", 12)
      params:hide("nb_harvest_group")
   
      params:add_separator("nb_synth", "løv")
      
      params:add{
         type        = "control",
         id          = "nb_synth_amp",
         name        = "volum",
         controlspec = controlspec.new(0, 1, "lin", 0.01, 0.8),
         action      = function(x)
            set_param("amp", x)
         end
      }
      
      params:add{
         type        = "control",
         id          = "nb_timbre",
         name        = "klangfarge",
         controlspec = controlspec.new(0, 1, "lin", 0.01, 0.2),
         action      = function(x)
            set_param("timbre", x)
         end
      }
      
      params:add{
         type        = "control",
         id          = "nb_noise",
         name        = "støy",
         controlspec = controlspec.new(0, 1, "lin", 0.01, 0.3),
         action      = function(x)
            set_param("noise", x)
         end
      }
      
      params:add{
         type        = "control",
         id          = "nb_bias",
         name        = "terskel",
         controlspec = controlspec.new(0, 1, "lin", 0.01, 0.6),
         action      = function(x)
            set_param("bias", x)
         end
      }
      
      params:add{
         type        = "control",
         id          = "nb_shape",
         name        = "form",
         controlspec = controlspec.new(0, 1, "lin", 0.01, 0.1),
         action      = function(x)
            set_param("shape", x)
         end
      }
      
      params:add{
         type        = "option",
         id          = "nb_loop",
         name        = "repetisjon",
         options     = {"nei", "ja"},
         default     = 1,
         action      = function(x)
            set_param("loop", x - 1)
         end
      }
      
      params:add{
         type        = "control",
         id          = "nb_max_attack",
         name        = "vekst",
         controlspec = controlspec.new(0.001, 10, "exp", 0.01, 1, "sek"),
         action      = function(x)
            set_param("max_attack", x)
         end
      }
      
      params:add{
         type        = "control",
         id          = "nb_max_release",
         name        = "forfall",
         controlspec = controlspec.new(0.001, 10, "exp", 0.01, 3, "sek"),
         action      = function(x)
            set_param("max_release", x)
         end
      }
      
      params:add{
         type        = "control",
         id          = "nb_scale",
         name        = "størrelse",
         controlspec = controlspec.new(0.01, 1, "lin", 0.01, 1),
         action      = function(x)
            set_param("scale", x)
         end
      }
      
      -- if you want to use the fx mod environment, keep these.
      params:add_control("nb_harvest_send_a", "send a", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
      params:set_action("nb_harvest_send_a", function(val) set_param("sendA", val) end)
      
      params:add_control("nb_harvest_send_b", "send b", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
      params:set_action("nb_harvest_send_b", function(val) set_param("sendB", val) end)
   end

   function add_nb_harvest_player()
      local player = {
         alloc = vx.new(NUM_VOICES, 2),
         slot = {}
      }

      function player:describe()
         return {
            name = "nb_harvest",
            supports_bend = false,
            supports_slew = false
         }
      end
      
      function player:active()
         if self.name ~= nil then
            params:show("nb_harvest_group")
            if md.is_loaded("fx") == false then
            params:hide("nb_harvest_send_a") -- will automatically hide these params if fx mod is not active
            params:hide("nb_harvest_send_b")
            end
            _menu.rebuild_params()
         end
      end

      function player:inactive()
         if self.name ~= nil then
            params:hide("nb_harvest_group")
            _menu.rebuild_params()
         end
      end

      function player:stop_all()
         dont_panic()
      end

      function player:modulate(val)
         
      end

      function player:set_slew(s)
         
      end

      function player:pitch_bend(note, amount)

      end

      function player:modulate_note(note, key, value)

      end

      function player:note_on(note, vel)
         local freq = mu.note_num_to_freq(note)
         local slot = self.slot[note]
         if slot == nil then
            slot = self.alloc:get()
            slot.count = 1
         end
         local voice = slot.id - 1 -- sc is zero indexed!
         slot.on_release = function()
            osc.send({ "localhost", 57120 }, "/nb_harvest/note_off", {voice})
         end
         self.slot[note] = slot
         osc.send({ "localhost", 57120 }, "/nb_harvest/note_on", {voice, freq, vel})
      end

      function player:note_off(note)
         local slot = self.slot[note]
         if slot ~= nil then
            self.alloc:release(slot)
         end
         self.slot[note] = nil
      end

      function player:add_params()
         add_nb_harvest_params()
      end

      if note_players == nil then
         note_players = {}
      end

      note_players["nb_harvest"] = player
   end

   local function pre_init()
      add_nb_harvest_player()
   end

   md.hook.register("script_pre_init", "nb_harvest pre init", pre_init)
