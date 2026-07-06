
--[[
	Pouches
		ver. 1.00
		by Learwolf
	
	Description:
		This script allows server owners to give out "pouches" that can store specific items, such as ingredients, keys, potions or scrolls.
		
		When a player receives a specified pouch, they can use it in their inventory by dragging it onto their character.
		At that point, they a menu will appear asking if they want to deposit or withdraw all of the items that pouch can contain.
		If they select deposit, the specific pouch contents will removed from the players inventory, and stored to a server side database.
		If they select withdraw, the specific pouch contents will removed from a server side database, and added to the players inventory.
		
		The storage space is tied to the actual player, meaning player B wont be able to deposit or remove any items from players A's pouch, even if player B picks up players A's pouch.
		
		This allows server owners to give their players a means to reduce inventory clutter, as well as reduce being overburdened by a bunch of items.
	
	Notes:
		When depositing items into the pouch, players inventory screens are forced closed and players are temporarily disabled while the items are being removed.
		This disabled portion should occur so fast that it is virtually unnoticeable by players.
		The reason this occurs, is to prevent a possible item duplication exploit if the server is lagging when players deposit their items.
	
	Important:
		Avoid trying to make soulgem pouches, as pouches only save item refId's and counts, so souls will be wiped.
		If requested enough, I may rewrite the script to incorporate souls in the future, but it is not currently planned.
	
	Installation:
		- Place this 'pouches.lua' script inside your 'server/scripts/custom' folder.
		- Open the 'customScripts.lua' found inside your 'server/scripts' folder.
		- Add the following text on a new line:
				pouches = require("custom.pouches")
		- Make sure there are no '--' characters infront of it (as that disables the script).
		- Save 'customScripts.lua' and relaunch your server.
	
	Version History:
		
		1.00 - 12/15/2020
			- Initial Release.
--]]


pouches = {}

--==----==----==----==----==----==----==--
--										--
--    Feel free to customize     		--
-- 			        the below options:  --
--										--
--==----==----==----==----==----==----==--
local pouchMsgColor = "#CAA560" -- The default color used on this scripts message GUIs.

local giveEveryPlayerPouchesOnLogin = false -- Setting this to true will make sure every player gets 1 of each pouch 
											-- if their name is missing from the pouches database yet.
											-- If false, you must distribute the pouches out by other methods, such as give aways.

-- This includes configs for the pouch refIds listed above.
local pouchConfig = {

	-- You can add your own pouches inside this config section. See the below for examples of what-does-what.
	-- IMPORTANT: Pouches only save item refId's and counts. SOULS WILL NOT BE SAVED!!!!!
	
	["pouch_ingredients"] = { -- This is the refId of the item pouch. This should ALWAYS be lowercase!
		pouchName = "Pouch: Ingredients", -- The pouch refId's actual in-game displayed name.
		pouchWeight = 0.1, -- How much the pouch weighs.
		pouchValue = 0, -- The pouches value.
		pouchIcon = "m\\misc_dwe_satchel00.dds", -- The icon that pouches use.
		pouchModel = "m\\dwemer_satchel00.NIF", -- The model that pouches use.
		pouchDB = "pouch_db_ingredients", -- Unique per each pouch, in order to save to a unique database and avoid server lag.
		pouchGUID = 50161, -- This number should always be a different and unique number.
		contentsName = "Ingredient", -- This is the singular name of this pouches contents in the menu display.
		contentsNamePlural = "Ingredients", -- This is the plural name of this pouches contents in the menu display.
		allowedRefIds = { -- The item refIds that can be added to this specific pouch.
			-- * All of these must be lowercase, even if they are displayed as uppercase in the construction set!
			"food_kwama_egg_01","food_kwama_egg_02","ingred_6th_corprusmeat_01","ingred_6th_corprusmeat_02","ingred_6th_corprusmeat_03","ingred_6th_corprusmeat_04","ingred_6th_corprusmeat_05","ingred_6th_corprusmeat_06","ingred_6th_corprusmeat_07","ingred_adamantium_ore_01","ingred_alit_hide_01","ingred_ash_salts_01","ingred_ash_yam_01","ingred_bc_ampoule_pod","ingred_bc_bungler's_bane","ingred_bc_coda_flower","ingred_bc_hypha_facia","ingred_bc_spore_pod","ingred_bear_pelt","ingred_belladonna_01","ingred_belladonna_02","ingred_bittergreen_petals_01","ingred_black_anther_01","ingred_black_lichen_01","ingred_bloat_01","ingred_blood_innocent_unique","ingred_boar_leather","ingred_bonemeal_01","ingred_bread_01","ingred_bread_01_uni2","ingred_bread_01_uni3","ingred_chokeweed_01","ingred_comberry_01","ingred_coprinus_01","ingred_corkbulb_root_01","ingred_corprus_weepings_01","ingred_crab_meat_01","ingred_cursed_daedras_heart_01","ingred_dae_cursed_diamond_01","ingred_dae_cursed_emerald_01","ingred_dae_cursed_pearl_01","ingred_dae_cursed_raw_ebony_01","ingred_dae_cursed_ruby_01","ingred_daedra_skin_01","ingred_daedras_heart_01","ingred_diamond_01","ingred_dreugh_wax_01","ingred_durzog_meat_01","ingred_ectoplasm_01","ingred_emerald_01","ingred_emerald_pinetear","ingred_eyeball","ingred_eyeball_unique","ingred_fire_petal_01","ingred_fire_salts_01","ingred_frost_salts_01","ingred_ghoul_heart_01","ingred_gold_kanet_01","ingred_gold_kanet_unique","ingred_golden_sedge_01","ingred_gravedust_01","ingred_gravetar_01","ingred_green_lichen_01","ingred_guar_hide_01","ingred_guar_hide_girith","ingred_guar_hide_marsus","ingred_hackle-lo_leaf_01","ingred_heartwood_01","ingred_heather_01","ingred_holly_01","ingred_horker_tusk_01","ingred_horn_lily_bulb_01","ingred_hound_meat_01","ingred_human_meat_01","ingred_innocent_heart","ingred_kagouti_hide_01","ingred_kresh_fiber_01","ingred_kwama_cuttle_01","ingred_lloramor_spines_01","ingred_marshmerrow_01","ingred_meadow_rye_01","ingred_moon_sugar_01","ingred_muck_01","ingred_netch_leather_01","ingred_nirthfly_stalks_01","ingred_noble_sedge_01","ingred_pearl_01","ingred_racer_plumes_01","ingred_rat_meat_01","ingred_raw_ebony_01","ingred_raw_glass_01","ingred_raw_glass_tinos","ingred_raw_stalhrim_01","ingred_red_lichen_01","ingred_resin_01","ingred_roobrush_01","ingred_ruby_01","ingred_russula_01","ingred_saltrice_01","ingred_scales_01","ingred_scamp_skin_01","ingred_scathecraw_01","ingred_scrap_metal_01","ingred_scrib_cabbage_01","ingred_scrib_jelly_01","ingred_scrib_jelly_02","ingred_scrib_jerky_01","ingred_scuttle_01","ingred_shalk_resin_01","ingred_sload_soap_01","ingred_snowbear_pelt_unique","ingred_snowwolf_pelt_unique","ingred_stoneflower_petals_01","ingred_sweetpulp_01","ingred_timsa-come-by_01","ingred_trama_root_01","ingred_treated_bittergreen_uniq","ingred_udyrfrykte_heart","ingred_vampire_dust_01","ingred_void_salts_01","ingred_wickwheat_01","ingred_willow_anther_01","ingred_wolf_heart","ingred_wolf_pelt","ingred_wolfsbane_01","poison_goop00"
		}
	},
	["pouch_keys"] = {
		pouchName = "Pouch: Keys",
		pouchWeight = 0.1,
		pouchValue = 0,
		pouchIcon = "m\\misc_dwe_satchel00.dds",
		pouchModel = "m\\dwemer_satchel00.NIF",
		pouchDB = "pouch_db_keys", -- Unique per each pouch, in order to save to a unique database and avoid server lag.
		pouchGUID = 50163,
		contentsName = "Key", -- This is the singular name of this pouches contents in the menu display.
		contentsNamePlural = "Keys", -- This is the plural name of this pouches contents in the menu display.
		allowedRefIds = { 
			"key_abebaalslaves_01","key_addamasartusslaves_01","key_adibael","key_aharunartusslaves_01","key_ahnassi","key_ald_redaynia","key_aldruhn_underground","key_aldsotha","key_aleft_chest","key_alvur","key_andalen_chest","key_andalen_tomb","key_andas_tomb","key_andavel_tomb","key_andrethi_chest","key_andules_chest","key_anja","key_aralen","key_aran_tomb","key_arano_chest","key_arano_door","key_archcanon_private","key_arenim","key_arenim_chest","key_arkngthunch_chest","key_armigers_stronghold","key_arobarmanor_01","key_arobarmanorguard_01","key_arrile","key_arvs-drelen_cell","key_aryon_chest","key_ashalmawia_prisoncell","key_ashirbadon","key_ashmelech","key_ashmelech_chest","key_ashurninibi","key_ashurninibi_lost","key_assarnud","key_assarnudslaves_01","key_assemanu_01","key_assemanu_02","key_assi","key_assi_serimilk","key_aurane1","key_balmorag_tong_01","key_balmorag_tong_02","key_baram_tomb","key_berandas","key_bivaleteneran_01","key_bolayn","key_bols","key_brallion","key_brinne_chest","key_bthanchend_chest","key_bthuand","key_cabin","key_caius_cosades","key_calderaslaves_01","key_camp","key_caryarel","key_cell_buckmoth_01","key_cell_ebonheart_01","key_chest_aryniorethi_01","key_chest_avonravel_01","key_chest_brilnosullarys_01","key_chest_coduscallonus_01","key_chest_drinarvaryon_01","key_ciennesintieve_01","key_dareleth_tomb","key_dawnvault","key_desele","key_divayth00","key_divayth01","key_divayth02","key_divayth03","key_divayth04","key_divayth05","key_divayth06","key_divayth07","key_divayth_fyr","key_door_mudan00","key_dralas_chest","key_dralas_tomb","key_dralor","key_draramu","key_drarayne_thelas","key_dreloth_tomb","key_dren_manor","key_dren_storage","key_drenplantationslaves_01","key_dreynos","key_dubdilla","key_dulnea_ralaal","key_dumbuk_strongbox","key_dura_gra-bol","key_durgok","key_duskvault","key_dwe_satchel00","key_ebon_tomb","key_eldafire","key_eldrar","key_elmussadamori","key_erich","key_fadathram_tomb","key_falaanamo","key_falas tomb keepers","key_falas tomb keepers_2","key_falas_chest","key_falas_tomb","key_fals","key_farusea_salas","key_favel_chest","key_fedar","key_fetid_dreugh_grotto","key_fg_nchur","key_forge of rolamus","key_fqt","key_galmis","key_galom_daeus","key_gatekeeper","key_gatewayinnslaves_01","key_gen_tomb","key_gimothran","key_gimothran_chest","key_gimothran_tomb","key_gindrala","key_gnisis_eggmine","key_gro-bagrat","key_gshipwreck","key_gustav_chest","key_gyldenhul","key_habinbaesslaves_01","key_hanarai_assutlanipal","key_hasphat_antabolis","key_hasphat_antabolis2","key_helas_tomb","key_helvi","key_heran","key_hinnabi","key_hinnabislaves_01","key_hircine1","key_hircine2","key_hircine3","key_hlaalo_manor","key_hlormarenslaves_01","key_hodlismod","key_huleen's_hut","key_hvaults1","key_hvaults2","key_ibardad","key_ibardad_tomb","key_ienasa","key_ienith_chest","key_ienith_tomb","key_impcomsecrdoor","key_indalen","key_indalen_tomb","key_indaren","key_irgola","key_itar","key_ivrosa","key_j'zhirr","key_jeanne","key_kagouti_colony","key_keelraniur","key_kind","key_kogoruhn_sewer","key_kudanatslaves_01","key_lassnr_well","key_lleran_tomb","key_llervu","key_llethervari_01","key_llethri","key_llethrimanor_01","key_madach_room","key_malpenixblonia_01","key_maren_tomb","key_marvani_tomb","key_maryn","key_mebastien","key_menta_na","key_mette","key_miles","key_minabi","key_minabislaves_01","key_ministry_cells","key_ministry_ext","key_ministry_sectors","key_miun_gei","key_molagmarslaves_01","key_morvaynmanor","key_mudan_dragon","key_murudius_01","key_mzahnch_chest","key_mzanchend_chest","key_mzuleft","key_nchardahrk","key_nchardahrk_chest","key_nchuleftingth","key_nchuleftingth_chest","key_nedhelas","key_nelas_chest","key_nelothtelnaga","key_nelothtelnaga2","key_nelothtelnaga3","key_nelothtelnaga4","key_nerano_chest","key_neranomanor","key_nileno_dorvayn","key_norvayn_chest","key_norvayn_tomb","key_nuncius","key_nuncius2","key_nund","key_obscure_alit_warren","key_odibaal","key_odirniran","key_odral_helvi","key_odros","key_olms_storage","key_omalen_tomb","key_omani_01","key_omaren_chest","key_orethi_tomb","key_oritius","key_orvas_dren","key_othrelas_door","key_palansour","key_panatslaves_01","key_pellecia aurrus","key_persius mercius","key_pirate","key_private quarters","key_punsabanit","key_ra'zhid","key_ralen_hlaalo","key_ravel_chest","key_ravel_tomb","key_raviro_tomb","key_redoran_basic","key_redoran_treasury","key_relien_rirne","key_rethandus_chest","key_rethandus_tomb","key_rothan_tomb","key_rotheranslaves_01","key_rothran","key_rufinus_alleius","key_rvaults1","key_sadrithmoraslaves_01","key_sadryon_tomb","key_saetring","key_salvel_chest","key_salvel_tomb","key_sandas","key_sandas_tomb","key_sarano_chest","key_sarano_tomb","key_saren_chest","key_saren_tomb","key_sarethi_tomb","key_sarethimanor_01","key_saryoni","key_sarys_chest","key_saturanslaves_01","key_savel_tomb","key_savilecagekey","key_savilecagekey02","key_senim_chest","key_senim_tomb","key_sethan","key_shaadnius","key_shaadniusslaves_01","key_shashev","key_shilipuran","key_shipwreck9-11","key_shushanslaves_01","key_shushishi","key_shushishislaves","key_sinsibadonslaves_01","key_sirilonwe","key_skeleton","key_slave_addamasartus","key_sn_warehouse","key_standard_01","key_standard_01_darvam hlaren","key_standard_01_hassour zainsub","key_standard_01_pel_fort_prison","key_standard_01_pel_guard_tower","key_standard_darius_chest","key_summoning_room","key_suran_slave","key_suranslaves_01","key_table_mudan00","key_tel_aruhn_slave1","key_telaruhnslaves_01","key_telbranoraslaves_01","key_telbranoratower","key_telvosjailslaves_01","key_temple_01","key_tgbt","key_thalas_tomb","key_tharys_chest","key_thelas_chest","key_thendas","key_thiralas_tomb","key_thorek","key_trib_dwe00","key_trib_dwe01","key_trib_dwe02","key_tukushapal_1","key_tureynul","key_tuvesobeleth_01","key_tv_ct","key_tvault","key_ulvil","key_vandus_tomb","key_varoprivate","key_varostorage","key_velas","key_venim","key_venimmanor","key_verelnim_tomb","key_vivec_arena_cell","key_vivec_hlaalu_cell","key_vivec_redoran_cell","key_vivec_secret","key_vivec_telvanni_cell","key_viveclizardheadslave_01","key_vivectelvannislaves_01","key_volrina_01","key_vorarhelas","key_widow_vabdas","key_wormlord_tomb","key_yagram","key_yakanalitslaves_01","key_yinglingbasement","key_zainsipiluslaves_01","key_zebabislaves_01","mamaea cell key","mamaea quarters key","misc_dwrv_ark_key00","ministry_truth_ext"
		}
	},
	["pouch_potions"] = {
		pouchName = "Pouch: Potions",
		pouchWeight = 0.1,
		pouchValue = 0,
		pouchIcon = "m\\misc_dwe_satchel00.dds",
		pouchModel = "m\\dwemer_satchel00.NIF",
		pouchDB = "pouch_db_potions", -- Unique per each pouch, in order to save to a unique database and avoid server lag.
		pouchGUID = 50164,
		contentsName = "Potion", -- This is the singular name of this pouches contents in the menu display.
		contentsNamePlural = "Potions", -- This is the plural name of this pouches contents in the menu display.
		allowedRefIds = { -- Vanilla Potions:
			"potion_local_brew_01","potion_nord_mead","potion_skooma_01","potion_cyro_whiskey_01","potion_comberry_wine_01","potion_cyro_brandy_01","potion_comberry_brandy_01","potion_local_brew_01","potion_local_liquor_01","potion_t_bug_musk_01","p_burden_s","p_fire_shield_s","p_fortify_endurance_s","p_fortify_personality_s","p_fortify_speed_s","p_fortify_strength_s","p_fortify_health_s","p_invisibility_s","p_light_s","p_lightning shield_s","p_night-eye_s","p_paralyze_s","p_reflection_s","p_fire resistance_s","p_magicka_resistance_s","p_poison_resistance_s","p_shock_resistance_s","p_restore_agility_s","p_restore_endurance_s","p_restore_intelligence_s","p_restore_luck_s","p_restore_personality_s","p_restore_speed_s","p_restore_strength_s","p_restore_willpower_s","p_restore_fatigue_s","p_silence_s","p_spell_absorption_s","p_levitation_s","p_fortify_fatigue_s","p_burden_c","p_burden_b","p_burden_q","p_burden_e","p_drain_agility_q","p_drain_endurance_q","p_drain_intelligence_q","p_drain_luck_q","p_drain_magicka_q","p_drain_personality_q","p_drain_speed_q","p_drain_strength_q","p_drain willpower_q","p_feather_c","p_feather_b","p_feather_e","p_feather_q","p_fire_shield_c","p_fire_shield_b","p_fire_shield_e","p_fire_shield_q","p_fortify_agility_c","p_fortify_agility_b","p_fortify_agility_q","p_fortify_agility_e","p_fortify_endurance_c","p_fortify_endurance_b","p_fortify_endurance_q","p_fortify_endurance_e","p_fortify_fatigue_c","p_fortify_fatigue_b","p_fortify_fatigue_e","p_fortify_fatigue_q","p_fortify_health_c","p_fortify_health_e","p_fortify_health_q","p_fortify_intelligence_c","p_fortify_intelligence_b","p_fortify_intelligence_e","p_fortify_intelligence_q","p_fortify_luck_c","p_fortify_luck_b","p_fortify_luck_q","p_fortify_luck_e","p_fortify_magicka_c","p_fortify_magicka_e","p_fortify_magicka_q","p_fortify_magicka_b","p_fortify_personality_c","p_fortify_personality_e","p_fortify_personality_b","p_fortify_personality_q","p_fortify_speed_c","p_fortify_speed_b","p_fortify_speed_q","p_fortify_speed_e","p_fortify_strength_c","p_fortify_strength_b","p_fortify_strength_e","p_fortify_strength_q","p_fortify_willpower_c","p_fortify_willpower_b","p_fortify_willpower_q","p_fortify_willpower_e","p_frost_shield_c","p_frost_shield_b","p_frost_shield_e","p_frost_shield_q","p_invisibility_c","p_invisibility_b","p_invisibility_q","p_invisibility_e","p_jump_c","p_jump_b","p_jump_e","p_jump_s","p_jump_q","p_levitation_c","p_levitation_b","p_levitation_q","p_levitation_e","p_light_c","p_light_b","p_light_e","p_light_q","p_lightning shield_c","p_lightning shield_e","p_lightning shield_q","p_lightning shield_b","p_night-eye_c","p_night-eye_b","p_night-eye_q","p_night-eye_e","p_paralyze_c","p_paralyze_b","p_paralyze_e","p_paralyze_q","p_reflection_c","p_reflection_b","p_reflection_q","p_reflection_e","p_disease_resistance_c","p_disease_resistance_s","p_disease_resistance_b","p_disease_resistance_q","p_disease_resistance_e","p_fire_resistance_c","p_fire_resistance_b","p_fire_resistance_q","p_fire_resistance_e","p_frost_resistance_c","p_frost_resistance_b","p_frost_resistance_e","p_frost_resistance_q","p_magicka_resistance_c","p_magicka_resistance_b","p_magicka_resistance_e","p_magicka_resistance_q","p_poison_resistance_c","p_poison_resistance_b","p_poison_resistance_e","p_poison_resistance_q","p_shock_resistance_c","p_shock_resistance_b","p_shock_resistance_e","p_shock_resistance_q","p_restore_agility_c","p_restore_agility_b","p_restore_agility_q","p_restore_agility_e","p_restore_endurance_c","p_restore_endurance_b","p_restore_endurance_q","p_restore_endurance_e","p_restore_fatigue_c","p_restore_fatigue_b","p_restore_fatigue_q","p_restore_fatigue_e","p_restore_health_c","p_restore_intelligence_c","p_restore_intelligence_e","p_restore_intelligence_q","p_restore_intelligence_b","p_restore_luck_b","p_restore_luck_q","p_restore_luck_e","p_restore_luck_c","p_restore_personality_b","p_restore_personality_c","p_restore_personality_e","p_restore_personality_q","p_restore_speed_c","p_restore_speed_b","p_restore_speed_q","p_restore_speed_e","p_restore_magicka_c","p_restore_magicka_b","p_restore_magicka_q","p_restore_magicka_e","p_restore_strength_c","p_restore_strength_b","p_restore_strength_q","p_restore_strength_e","p_restore_willpower_c","p_restore_willpower_b","p_restore_willpower_q","p_restore_willpower_e","p_chameleon_c","p_chameleon_b","p_chameleon_s","p_chameleon_q","p_chameleon_e","p_silence_c","p_silence_b","p_silence_q","p_silence_e","p_spell_absorption_c","p_spell_absorption_b","p_spell_absorption_q","p_spell_absorption_e","p_swift_swim_c","p_swift_swim_b","p_swift_swim_q","p_swift_swim_e","p_restore_health_b","p_restore_health_q","p_restore_health_e","potion_ancient_brandy","p_almsivi_intervention_s","p_detect_creatures_s","p_cure_common_s","p_cure_blight_s","p_cure_paralyzation_s","p_cure_poison_s","p_detect_key_s","p_dispel_s","p_fortify_agility_s","p_fortify_intelligence_s","p_fortify_luck_s","p_fortify_willpower_s","p_fortify_health_b","p_fortify_magicka_s","p_mark_s","p_frost_resistance_s","p_slowfall_s","p_telekinesis_s","p_water_breathing_s","p_water_walking_s","p_vintagecomberrybrandy1","p_frost_shield_s","p_restore_magicka_s","p_fortify_attack_e","p_cure_common_unique","p_restore_health_s","p_detect_enchantment_s","p_quarrablood_unique","p_sinyaramen_unique","p_heroism_s","p_lovepotion_unique","p_recall_s","potion_local_brew_01","pyroil_tar_unique","p_dwemer_lubricant00","verminous_fabricant_elixir","hulking_fabricant_elixir","p_imperfect_elixir"
		},
		customRecordType = "potion", -- This will insert selected the specified custom record type into the pouch.
		--customRecordPrefix = "$custom_potion_" -- If you want to insert a specific generated record prefix, such as "custom_potion_", insert the prefix here and uncomment this.
	},
	["pouch_scrolls"] = {
		pouchName = "Pouch: Scrolls",
		pouchWeight = 0.1,
		pouchValue = 0,
		pouchIcon = "m\\misc_dwe_satchel00.dds",
		pouchModel = "m\\dwemer_satchel00.NIF",
		pouchDB = "pouch_db_scrolls", -- Unique per each pouch, in order to save to a unique database and avoid server lag.
		pouchGUID = 50165,
		contentsName = "Scroll", -- This is the singular name of this pouches contents in the menu display.
		contentsNamePlural = "Scrolls", -- This is the plural name of this pouches contents in the menu display.
		allowedRefIds = { -- Vanilla Scrolls:
			"sc_paper plain","sc_paper_plain_01_canodia","sc_almsiviintervention","sc_alvusiaswarping","sc_argentglow","sc_balefulsuffering","sc_blackdeath","sc_blackdespair","sc_blackfate","sc_blackmind","sc_blackscorn","sc_blacksloth","sc_blackstorm","sc_blackweakness","sc_bloodfire","sc_bloodthief","sc_bodily_restoration","sc_brevasavertedeyes","sc_celerity","sc_chappy_sniper_test","sc_chridittepanacea","sc_corruptarcanix","sc_cureblight_ranged","sc_daerirsmiracle","sc_dawnsprite","sc_daydenespanacea","sc_daynarsairybubble","sc_dedresmasterfuleye","sc_didalasknack","sc_divineintervention","sc_drathissoulrot","sc_drathiswinterguest","sc_ekashslocksplitter","sc_elementalburstfire","sc_elementalburstfrost","sc_elementalburstshock","sc_elevramssty","sc_fadersleadenflesh","sc_feldramstrepidation","sc_fiercelyroastthyenemy_unique","sc_fifthbarrier","sc_firstbarrier","sc_flamebane","sc_flameguard","sc_fourthbarrier","sc_fphyggisgemfeeder","sc_frostbane","sc_frostguard","sc_galmsesseal","sc_gamblersprayer","sc_golnaraseyemaze","sc_gonarsgoad","sc_greaterdomination","sc_greydeath","sc_greydespair","sc_greyfate","sc_greymind","sc_greyscorn","sc_greysloth","sc_greyweakness","sc_healing","sc_heartwise","sc_hellfire","sc_hiddenkiller","sc_icarianflight","sc_illneasbreath","sc_inaschastening","sc_inasismysticfinger","sc_insight","sc_invisibility","sc_leaguestep","sc_lesserdomination","sc_llirosglowingeye","sc_lordmhasvengeance","sc_mageseye","sc_mageweal","sc_manarape","sc_mark","sc_messengerscroll","sc_mindfeeder","sc_mondensinstigator","sc_nerusislockjaw","sc_ninthbarrier","sc_oathfast","sc_ondusisunhinging","sc_princeovsbrightball","sc_psychicprison","sc_purityofbody","sc_radiyasicymask","sc_radrenesspellbreaker","sc_reddeath","sc_reddespair","sc_redfate","sc_redmind","sc_redscorn","sc_redsloth","sc_redweakness","sc_restoration","sc_reynosbeastfinder","sc_reynosfins","sc_salensvivication","sc_savagemight","sc_savagetyranny","sc_secondbarrier","sc_selisfieryward","sc_selynsmistslippers","sc_sertisesporphyry","sc_shockbane","sc_shockguard","sc_sixthbarrier","sc_stormward","sc_summondaedroth_hto","sc_summonflameatronach","sc_summonfrostatronach","sc_summongoldensaint","sc_summonskeletalservant","sc_supremedomination","sc_taldamsscorcher","sc_telvinscourage","sc_tendilstrembling","sc_tevilspeace","sc_tevralshawkshaw","sc_thirdbarrier","sc_tinurshoptoad","sc_toususabidingbeast","sc_tranasasspellmire","sc_tranasasspelltrap","sc_tranasasspelltwist","sc_ulmjuicedasfeather","sc_uthshandofheaven","sc_vaerminaspromise","sc_vigor","sc_vitality","sc_warriorsblessing","sc_windform","sc_windwalker"
		},
		customRecordType = "book", -- This will insert selected the specified custom record type into the pouch.
		customRecordRequiresEnchantment = true 	-- If this line does not exist at all, it will completely ignore this check.
												-- If this line exists and is true, the custom record requires an enchantment in order to be deposited. (Example: enchanted scrolls.)
												-- If this line exists and is false, the custom record must NOT have an enchantment in order to be deposited. (Example: Books.)
												
	},
	["pouch_books"] = {
		pouchName = "Pouch: Books",
		pouchWeight = 0.1,
		pouchValue = 0,
		pouchIcon = "m\\misc_dwe_satchel00.dds",
		pouchModel = "m\\dwemer_satchel00.NIF",
		pouchDB = "pouch_db_books", -- Unique per each pouch, in order to save to a unique database and avoid server lag.
		pouchGUID = 50166,
		contentsName = "Book", -- This is the singular name of this pouches contents in the menu display.
		contentsNamePlural = "Books", -- This is the plural name of this pouches contents in the menu display.
		allowedRefIds = { -- Vanilla Books:
			-- Vanilla Books, Notes and Scrolls (that arnt enchanted scrolls):
			--"sc_paper plain","sc_paper_plain_01_canodia",
			"text_paper_roll_01",
			"bookskill_acrobatics2","bk_houseoftroubles_o","bk_mixedunittactics","bk_houseoftroubles_c","bk_blasphemousrevenants","bk_a1_1_directionscaiuscosades","bk_five_far_stars","sc_erna","bk_snowprince","bk_bmtrial_unique","bk_thirskhistory","bk_airship_captains_journal","sc_grandfatherfrost","sc_erna01","bk_sovngarde","bk_bm_aevar","bk_bm_stonemap","sc_unclesweetshare","bk_fur_armor","sc_jeleen","bk_colonyreport","bk_carniusnote","bk_bm_stockcert","sc_piratetreasure","bk_thirskhistory_revised_m","bk_thirskhistory_revised_f","sc_fur_armor","sc_fjellnote","sc_sjobalnote","sc_frosselnote","sc_fjaldingnote","bk_fryssajournal","bk_necrojournal","bk_leggejournal","sc_bloodynote_s","bk_colony_toralf","sc_witchnote","sc_rumornote_bm","bookskill_enchant1","bookskill_enchant2","bookskill_enchant3","bookskill_enchant4","bookskill_enchant5","bookskill_destruction1","bookskill_destruction2","bookskill_destruction3","bookskill_destruction4","bookskill_destruction5","bookskill_alteration1","bookskill_alteration2","bookskill_alteration3","bookskill_alteration4","bookskill_alteration5","bookskill_illusion1","bookskill_illusion2","bookskill_illusion3","bookskill_illusion4","bookskill_illusion5","bookskill_conjuration1","bookskill_conjuration2","bookskill_conjuration3","bookskill_conjuration4","bookskill_conjuration5","bookskill_mysticism1","bookskill_mysticism2","bookskill_mysticism3","bookskill_mysticism4","bookskill_mysticism5","bookskill_restoration1","bookskill_restoration2","bookskill_restoration3","bookskill_restoration4","bookskill_restoration5","bookskill_alchemy1","bookskill_alchemy2","bookskill_alchemy3","bookskill_alchemy4","bookskill_alchemy5","bookskill_unarmored1","bookskill_unarmored2","bookskill_unarmored3","bookskill_unarmored4","bookskill_unarmored5","bookskill_block1","bookskill_block2","bookskill_block3","bookskill_block4","bookskill_block5","bookskill_armorer1","bookskill_armorer2","bookskill_armorer3","bookskill_armorer4","bookskill_armorer5","bookskill_medium armor1","bookskill_medium armor2","bookskill_medium armor3","bookskill_medium armor4","bookskill_medium armor5","bookskill_heavy armor1","bookskill_heavy armor2","bookskill_heavy armor3","bookskill_heavy armor4","bookskill_heavy armor5","bookskill_blunt weapon1","bookskill_blunt weapon2","bookskill_blunt weapon3","bookskill_blunt weapon4","bookskill_blunt weapon5","bookskill_long blade1","bookskill_long blade2","bookskill_long blade3","bookskill_long blade4","bookskill_long blade5","bookskill_axe1","bookskill_axe2","bookskill_axe3","bookskill_axe4","bookskill_axe5","bookskill_spear1","bookskill_spear2","bookskill_spear3","bookskill_spear4","bookskill_spear5","bookskill_athletics1","bookskill_athletics2","bookskill_athletics3","bookskill_athletics4","bookskill_athletics5","bookskill_security1","bookskill_security2","bookskill_security3","bookskill_security4","bookskill_security5","bookskill_sneak1","bookskill_sneak2","bookskill_sneak3","bookskill_sneak4","bookskill_sneak5","bookskill_acrobatics1","bookskill_acrobatics2","bookskill_acrobatics3","bookskill_acrobatics4","bookskill_acrobatics5","bookskill_light armor1","bookskill_light armor2","bookskill_light armor3","bookskill_light armor4","bookskill_light armor5","bookskill_short blade1","bookskill_short blade2","bookskill_short blade3","bookskill_short blade4","bookskill_short blade5","bookskill_marksman1","bookskill_marksman2","bookskill_marksman3","bookskill_marksman4","bookskill_marksman5","bookskill_mercantile1","bookskill_mercantile2","bookskill_mercantile3","bookskill_mercantile4","bookskill_mercantile5","bookskill_speechcraft1","bookskill_speechcraft2","bookskill_speechcraft3","bookskill_speechcraft4","bookskill_speechcraft5","bookskill_hand to hand1","bookskill_hand to hand2","bookskill_hand to hand3","bookskill_hand to hand4","bookskill_hand to hand5","bk_livesofthesaints","bk_saryonissermons","bk_homiliesofblessedalmalexia","bk_pilgrimspath","bk_houseoftroubles_o","bk_doorsofthespirit","bk_mysteriousakavir","bk_spiritofnirn","bk_vivecandmephala","bk_istunondescosmology","bk_firmament","bk_manyfacesmissinggod","bk_frontierconquestaccommodat","bk_truenatureoforcs","bk_varietiesoffaithintheempire","bk_tamrielicreligions","bk_fivesongsofkingwulfharth","bk_wherewereyoudragonbroke","bk_nchunaksfireandfaith","bk_vampiresofvvardenfell1","bk_reflectionsoncultworship...","bk_galerionthemystic","bk_madnessofpelagius","bk_realbarenziah2","bk_realbarenziah3","bk_realbarenziah4","bk_overviewofgodsandworship","bk_fragmentonartaeum","bk_onoblivion","bk_invocationofazura","bk_mysticism","bk_originofthemagesguild","bk_specialfloraoftamriel","bk_oldways","bk_wildelves","bk_pigchildren","bk_redbookofriddles","bk_yellowbookofriddles","bk_guylainesarchitecture","bk_progressoftruth","bk_easternprovincesimpartial","bk_vampiresofvvardenfell2","bk_gnisiseggmineledger","bk_fortpelagiadprisonerlog","bk_mixedunittactics","bk_gnisiseggminepass","bk_houseoftroubles_c","bk_truenoblescode","bk_ngastakvatakvakis_c","bk_legionsofthedead","bk_darkestdarkness","bk_ngastakvatakvakis_o","bk_hanginggardenswasten","bk_itermerelsnotes","bk_tiramgadarscredentials","bk_corpsepreperation1_c","bk_corpsepreperation1_o","bk_sharnslegionsofthedead","bk_samarstarloversjournal","bk_spiritofthedaedra","bk_vagariesofmagica","bk_watersofoblivion","bk_legendaryscourge","bk_postingofthehunt","bk_talmarogkersresearches","bk_seniliasreport","bk_graspingfortune","bk_notefromsondaale","bk_shishireport","bk_galtisguvronsnote","bk_sottildescodebook","bk_notefromj'zhirr","bk_eastempirecompanyledger","bk_nemindasorders","bk_ordersforbivaleteneran","bk_treasuryreport","bk_treasuryorders","bk_blasphemousrevenants","bk_consolationsofprayer","bk_bookdawnanddusk","bk_cantatasofvivec","bk_anticipations","bk_ancestorsandthedunmer","bk_aedraanddaedra","bk_annotatedanuad","bk_childrensanuad","bk_arcturianheresy","bk_changedones","bk_childrenofthesky","bk_antecedantsdwemerlaw","bk_chroniclesnchuleft","bk_biographybarenziah1","bk_biographybarenziah2","bk_biographybarenziah3","bk_briefhistoryempire1","bk_briefhistoryempire2","bk_briefhistoryempire3","bk_briefhistoryempire4","bk_brothersofdarkness","bk_blackglove","bk_bluebookofriddles","bk_boethiahpillowbook","bk_a1_1_directionscaiuscosades","bk_a1_2_antabolistocosades","bk_a1_2_introtocadiusus","bk_a1_4_sharnsnotes","bk_a1_v_vivecinformants","bk_a1_7_huleeyainformant","bk_bookofdaedra","bk_arcanarestored","bk_bookoflifeandservice","bk_bookofrestandendings","bk_affairsofwizards","bk_calderarecordbook1","bk_calderarecordbook2","bk_auranefrernis1","bk_auranefrernis2","bk_auranefrernis3","bk_6thhouseravings","bk_calderaminingcontract","bk_abcs","bk_a1_11_zainsubaninotes","note to hrisskar","chargen statssheet","bk_notetocalderaslaves","bk_notetoinorra","bk_notetocalderaguard","bk_notetocalderamages","bk_falanaamonote","bk_notetovalvius","bk_notefromirgola","bk_notefrombildren","bk_notesoldout","bk_notefromferele","bk_dren_hlevala_note","bk_dren_shipping_log","bk_saryonisermonsmanuscript","bk_messagefrommasteraryon","bk_responsefromdivaythfyr","bk_honorthieves","bk_redbook426","bk_yellowbook426","bk_brownbook426","bk_orderfrommollismo","bk_blightpotionnotice","bk_propertyofjolda","bk_joldanote","bk_eggorders","bk_notefromradras","bk_thesevencurses","bk_thelostprophecy","bk_kagrenac'stools","bk_notetoamaya","bk_vivecs_plan","bk_vivec_murders","bk_saryoni_note","bk_vivec_no_murder","bk_dagoth_urs_plans","bk_notefromberwen","bk_varoorders","bk_storagenotice","bk_notetomenus","bk_notefrombugrol","bk_notefrombashuk","bk_notebyaryon","bk_beramjournal1","bk_beramjournal2","bk_beramjournal3","bk_beramjournal4","bk_beramjournal5","bk_impmuseumwelcome","bk_dwemermuseumwelcome","bk_pillowinvoice","bk_ravilamemorial","bk_fishystick","bk_kagrenac'splans_excl","bk_miungei","bk_ynglingledger","bk_ynglingletter","bk_indreledeed","bk_briefhistoryempire1_oh","bk_briefhistoryempire2_oh","bk_briefhistoryempire3_oh","bk_briefhistoryempire4_oh","bk_dispelrecipe_tgca","bk_a1_1_caiuspackage","bk_ashland_hymns","bk_words_of_the_wind","bk_five_far_stars","bk_provinces_of_tamriel","bk_galur_rithari's_papers","bk_kagrenac'sjournal_excl","bk_notes-kagouti mating habits","bk_notefromnelos","bk_notefromernil","bk_enamor","bk_wordsclanmother","bk_corpsepreperation2_c","bk_corpsepreperation3_c","bk_arkaytheenemy","bk_poisonsong1","bk_poisonsong2","bk_poisonsong3","bk_poisonsong4","bk_poisonsong5","bk_poisonsong6","bk_poisonsong7","bk_confessions","bk_hospitality_papers","bk_uleni's_papers","bk_redorancookingsecrets","bk_widowdeed","bk_guide_to_vvardenfell","bk_guide_to_vivec","bk_guide_to_balmora","bk_guide_to_ald_ruhn","bk_guide_to_sadrithmora","bk_seydaneentaxrecord","bk_a1_1_packagedecoded","bk_a2_1_sevenvisions","bk_a2_1_thestranger","bk_briefhistoryofwood","bk_realbarenziah1","bk_realbarenziah5","sc_messengerscroll","sc_summondaedroth_hto","bk_bartendersguide","bk_nerevarinenotice","bk_warehouse_log","bk_red_mountain_map","bk_arrilles_tradehouse","bk_talostreason","bk_a2_2_dagoth_message","bk_eggoftime","bk_divinemetaphysics","bk_a1_1_elone_to_balmora","bk_note","writ_yasalmibaal","writ_oran","writ_saren","writ_sadus","writ_vendu","writ_guril","writ_galasa","writ_mavon","writ_belvayn","writ_bemis","writ_brilnosu","writ_navil","writ_varro","writ_baladas","writ_bero","writ_therana","bk_great_houses","bk_chartermg","bk_charterfg","bk_ibardad_elante_notes","bookskill_destruction5_open","bookskill_axe5_open","bk_boethiah's glory_unique","bk_aedra_tarer_unique","bk_ocato_recommendation","bk_ajira1","bk_ajira2","cumanya's notes","sc_malaki","sc_vulpriss","bk_briefhistoryofwood_01","bk_landdeed_hhrd","bk_landdeedfake_hhrd","bk_stronghold_c_hlaalu","bk_stronghold_ld_hlaalu","bk_v_hlaaluprison","bk_hlaalu_vaults_ledger","sc_indie","bk_nerano","bk_shalitjournal_deal","bk_shalit_note","bk_drenblackmail","bk_notetomalsa","bk_redoran_vaults_ledger","bk_ilhermit_page","note_peke_utchoo","bk_clientlist","bk_contract_ralen","bk_letterfromllaalam","bk_letterfromjzhirr","bk_letterfromllaalam2","bk_letterfromgadayn","bk_leaflet_false","bk_telvanni_vault_ledger","bk_yagrum's_book","bk_lustyargonianmaid","bk_alchemistsformulary","bk_secretsdwemeranimunculi","bk_fellowshiptemple","bk_formygodsandemperor","bk_ordolegionis","bk_bartendersguide_01","bookskill_mystery5","bk_notetotelvon","bk_warofthefirstcouncil","bk_onmorrowind","bk_realnerevar","bk_nerevarmoonandstar","bk_saintnerevar","bk_shorthistorymorrowind","bk_falljournal_unique","bookskill_alchemy1","bookskill_speechcraft2","bk_livesofthesaints","bk_saryonissermons","bk_mysteriousakavir","bk_firmament","bk_tamrielicreligions","bk_easternprovincesimpartial","bk_houseoftroubles_c","bk_legionsofthedead","bk_graspingfortune","bk_consolationsofprayer","bk_bookdawnanddusk","bk_anticipations","bk_ancestorsandthedunmer","bk_annotatedanuad","bk_childrensanuad","bk_arcturianheresy","bk_childrenofthesky","bk_chroniclesnchuleft","bk_bookofdaedra","bk_bartendersguide","bk_yagrum's_book","bk_alchemistsformulary","bk_commontongue","bk_commontongue_irano","bk_irano_note","bk_alen_note","writ_berano","writ_hloggar","writ_alen","bk_playscript","bk_ahnia","bk_nermarcnotes","bk_custom_armor","book_dwe_pipe00","book_dwe_cogs00","book_dwe_mach00","book_dwe_water00","book_dwe_power_con00","book_dwe_metal_fab00","bk_teran_invoice","book_dwe_boom00","bk_diary_sailor","bk_dbcontract","bk_adren","bk_suicidenote","bk_artifacts_tamriel"
			-- Vanilla Books Only:
			--"bookskill_acrobatics2","bk_houseoftroubles_o","bk_mixedunittactics","bk_houseoftroubles_c","bk_blasphemousrevenants","bk_a1_1_directionscaiuscosades","bk_five_far_stars","bk_snowprince","bk_bmtrial_unique","bk_thirskhistory","bk_airship_captains_journal","bk_sovngarde","bk_bm_aevar","bk_bm_stonemap","bk_fur_armor","bk_colonyreport","bk_carniusnote","bk_bm_stockcert","bk_thirskhistory_revised_m","bk_thirskhistory_revised_f","bk_fryssajournal","bk_necrojournal","bk_leggejournal","bk_colony_toralf","bookskill_enchant1","bookskill_enchant2","bookskill_enchant3","bookskill_enchant4","bookskill_enchant5","bookskill_destruction1","bookskill_destruction2","bookskill_destruction3","bookskill_destruction4","bookskill_destruction5","bookskill_alteration1","bookskill_alteration2","bookskill_alteration3","bookskill_alteration4","bookskill_alteration5","bookskill_illusion1","bookskill_illusion2","bookskill_illusion3","bookskill_illusion4","bookskill_illusion5","bookskill_conjuration1","bookskill_conjuration2","bookskill_conjuration3","bookskill_conjuration4","bookskill_conjuration5","bookskill_mysticism1","bookskill_mysticism2","bookskill_mysticism3","bookskill_mysticism4","bookskill_mysticism5","bookskill_restoration1","bookskill_restoration2","bookskill_restoration3","bookskill_restoration4","bookskill_restoration5","bookskill_alchemy1","bookskill_alchemy2","bookskill_alchemy3","bookskill_alchemy4","bookskill_alchemy5","bookskill_unarmored1","bookskill_unarmored2","bookskill_unarmored3","bookskill_unarmored4","bookskill_unarmored5","bookskill_block1","bookskill_block2","bookskill_block3","bookskill_block4","bookskill_block5","bookskill_armorer1","bookskill_armorer2","bookskill_armorer3","bookskill_armorer4","bookskill_armorer5","bookskill_medium armor1","bookskill_medium armor2","bookskill_medium armor3","bookskill_medium armor4","bookskill_medium armor5","bookskill_heavy armor1","bookskill_heavy armor2","bookskill_heavy armor3","bookskill_heavy armor4","bookskill_heavy armor5","bookskill_blunt weapon1","bookskill_blunt weapon2","bookskill_blunt weapon3","bookskill_blunt weapon4","bookskill_blunt weapon5","bookskill_long blade1","bookskill_long blade2","bookskill_long blade3","bookskill_long blade4","bookskill_long blade5","bookskill_axe1","bookskill_axe2","bookskill_axe3","bookskill_axe4","bookskill_axe5","bookskill_spear1","bookskill_spear2","bookskill_spear3","bookskill_spear4","bookskill_spear5","bookskill_athletics1","bookskill_athletics2","bookskill_athletics3","bookskill_athletics4","bookskill_athletics5","bookskill_security1","bookskill_security2","bookskill_security3","bookskill_security4","bookskill_security5","bookskill_sneak1","bookskill_sneak2","bookskill_sneak3","bookskill_sneak4","bookskill_sneak5","bookskill_acrobatics1","bookskill_acrobatics2","bookskill_acrobatics3","bookskill_acrobatics4","bookskill_acrobatics5","bookskill_light armor1","bookskill_light armor2","bookskill_light armor3","bookskill_light armor4","bookskill_light armor5","bookskill_short blade1","bookskill_short blade2","bookskill_short blade3","bookskill_short blade4","bookskill_short blade5","bookskill_marksman1","bookskill_marksman2","bookskill_marksman3","bookskill_marksman4","bookskill_marksman5","bookskill_mercantile1","bookskill_mercantile2","bookskill_mercantile3","bookskill_mercantile4","bookskill_mercantile5","bookskill_speechcraft1","bookskill_speechcraft2","bookskill_speechcraft3","bookskill_speechcraft4","bookskill_speechcraft5","bookskill_hand to hand1","bookskill_hand to hand2","bookskill_hand to hand3","bookskill_hand to hand4","bookskill_hand to hand5","bk_livesofthesaints","bk_saryonissermons","bk_homiliesofblessedalmalexia","bk_pilgrimspath","bk_houseoftroubles_o","bk_doorsofthespirit","bk_mysteriousakavir","bk_spiritofnirn","bk_vivecandmephala","bk_istunondescosmology","bk_firmament","bk_manyfacesmissinggod","bk_frontierconquestaccommodat","bk_truenatureoforcs","bk_varietiesoffaithintheempire","bk_tamrielicreligions","bk_fivesongsofkingwulfharth","bk_wherewereyoudragonbroke","bk_nchunaksfireandfaith","bk_vampiresofvvardenfell1","bk_reflectionsoncultworship...","bk_galerionthemystic","bk_madnessofpelagius","bk_realbarenziah2","bk_realbarenziah3","bk_realbarenziah4","bk_overviewofgodsandworship","bk_fragmentonartaeum","bk_onoblivion","bk_invocationofazura","bk_mysticism","bk_originofthemagesguild","bk_specialfloraoftamriel","bk_oldways","bk_wildelves","bk_pigchildren","bk_redbookofriddles","bk_yellowbookofriddles","bk_guylainesarchitecture","bk_progressoftruth","bk_easternprovincesimpartial","bk_vampiresofvvardenfell2","bk_gnisiseggmineledger","bk_fortpelagiadprisonerlog","bk_mixedunittactics","bk_gnisiseggminepass","bk_houseoftroubles_c","bk_truenoblescode","bk_ngastakvatakvakis_c","bk_legionsofthedead","bk_darkestdarkness","bk_ngastakvatakvakis_o","bk_hanginggardenswasten","bk_itermerelsnotes","bk_tiramgadarscredentials","bk_corpsepreperation1_c","bk_corpsepreperation1_o","bk_sharnslegionsofthedead","bk_samarstarloversjournal","bk_spiritofthedaedra","bk_vagariesofmagica","bk_watersofoblivion","bk_legendaryscourge","bk_postingofthehunt","bk_talmarogkersresearches","bk_seniliasreport","bk_graspingfortune","bk_notefromsondaale","bk_shishireport","bk_galtisguvronsnote","bk_sottildescodebook","bk_notefromj'zhirr","bk_eastempirecompanyledger","bk_nemindasorders","bk_ordersforbivaleteneran","bk_treasuryreport","bk_treasuryorders","bk_blasphemousrevenants","bk_consolationsofprayer","bk_bookdawnanddusk","bk_cantatasofvivec","bk_anticipations","bk_ancestorsandthedunmer","bk_aedraanddaedra","bk_annotatedanuad","bk_childrensanuad","bk_arcturianheresy","bk_changedones","bk_childrenofthesky","bk_antecedantsdwemerlaw","bk_chroniclesnchuleft","bk_biographybarenziah1","bk_biographybarenziah2","bk_biographybarenziah3","bk_briefhistoryempire1","bk_briefhistoryempire2","bk_briefhistoryempire3","bk_briefhistoryempire4","bk_brothersofdarkness","bk_blackglove","bk_bluebookofriddles","bk_boethiahpillowbook","bk_a1_1_directionscaiuscosades","bk_a1_2_antabolistocosades","bk_a1_2_introtocadiusus","bk_a1_4_sharnsnotes","bk_a1_v_vivecinformants","bk_a1_7_huleeyainformant","bk_bookofdaedra","bk_arcanarestored","bk_bookoflifeandservice","bk_bookofrestandendings","bk_affairsofwizards","bk_calderarecordbook1","bk_calderarecordbook2","bk_auranefrernis1","bk_auranefrernis2","bk_auranefrernis3","bk_6thhouseravings","bk_calderaminingcontract","bk_abcs","bk_a1_11_zainsubaninotes","note to hrisskar","chargen statssheet","bk_notetocalderaslaves","bk_notetoinorra","bk_notetocalderaguard","bk_notetocalderamages","bk_falanaamonote","bk_notetovalvius","bk_notefromirgola","bk_notefrombildren","bk_notesoldout","bk_notefromferele","bk_dren_hlevala_note","bk_dren_shipping_log","bk_saryonisermonsmanuscript","bk_messagefrommasteraryon","bk_responsefromdivaythfyr","bk_honorthieves","bk_redbook426","bk_yellowbook426","bk_brownbook426","bk_orderfrommollismo","bk_blightpotionnotice","bk_propertyofjolda","bk_joldanote","bk_eggorders","bk_notefromradras","bk_thesevencurses","bk_thelostprophecy","bk_kagrenac'stools","bk_notetoamaya","bk_vivecs_plan","bk_vivec_murders","bk_saryoni_note","bk_vivec_no_murder","bk_dagoth_urs_plans","bk_notefromberwen","bk_varoorders","bk_storagenotice","bk_notetomenus","bk_notefrombugrol","bk_notefrombashuk","bk_notebyaryon","bk_beramjournal1","bk_beramjournal2","bk_beramjournal3","bk_beramjournal4","bk_beramjournal5","bk_impmuseumwelcome","bk_dwemermuseumwelcome","bk_pillowinvoice","bk_ravilamemorial","bk_fishystick","bk_kagrenac'splans_excl","bk_miungei","bk_ynglingledger","bk_ynglingletter","bk_indreledeed","bk_briefhistoryempire1_oh","bk_briefhistoryempire2_oh","bk_briefhistoryempire3_oh","bk_briefhistoryempire4_oh","bk_dispelrecipe_tgca","bk_a1_1_caiuspackage","bk_ashland_hymns","bk_words_of_the_wind","bk_five_far_stars","bk_provinces_of_tamriel","bk_galur_rithari's_papers","bk_kagrenac'sjournal_excl","bk_notes-kagouti mating habits","bk_notefromnelos","bk_notefromernil","bk_enamor","bk_wordsclanmother","bk_corpsepreperation2_c","bk_corpsepreperation3_c","bk_arkaytheenemy","bk_poisonsong1","bk_poisonsong2","bk_poisonsong3","bk_poisonsong4","bk_poisonsong5","bk_poisonsong6","bk_poisonsong7","bk_confessions","bk_hospitality_papers","bk_uleni's_papers","bk_redorancookingsecrets","bk_widowdeed","bk_guide_to_vvardenfell","bk_guide_to_vivec","bk_guide_to_balmora","bk_guide_to_ald_ruhn","bk_guide_to_sadrithmora","text_paper_roll_01","bk_seydaneentaxrecord","bk_a1_1_packagedecoded","bk_a2_1_sevenvisions","bk_a2_1_thestranger","bk_briefhistoryofwood","bk_realbarenziah1","bk_realbarenziah5","bk_bartendersguide","bk_nerevarinenotice","bk_warehouse_log","bk_red_mountain_map","bk_arrilles_tradehouse","bk_talostreason","bk_a2_2_dagoth_message","bk_eggoftime","bk_divinemetaphysics","bk_a1_1_elone_to_balmora","bk_note","writ_yasalmibaal","writ_oran","writ_saren","writ_sadus","writ_vendu","writ_guril","writ_galasa","writ_mavon","writ_belvayn","writ_bemis","writ_brilnosu","writ_navil","writ_varro","writ_baladas","writ_bero","writ_therana","bk_great_houses","bk_chartermg","bk_charterfg","bk_ibardad_elante_notes","bookskill_destruction5_open","bookskill_axe5_open","bk_boethiah's glory_unique","bk_aedra_tarer_unique","bk_ocato_recommendation","bk_ajira1","bk_ajira2","cumanya's notes","bk_briefhistoryofwood_01","bk_landdeed_hhrd","bk_landdeedfake_hhrd","bk_stronghold_c_hlaalu","bk_stronghold_ld_hlaalu","bk_v_hlaaluprison","bk_hlaalu_vaults_ledger","bk_nerano","bk_shalitjournal_deal","bk_shalit_note","bk_drenblackmail","bk_notetomalsa","bk_redoran_vaults_ledger","bk_ilhermit_page","note_peke_utchoo","bk_clientlist","bk_contract_ralen","bk_letterfromllaalam","bk_letterfromjzhirr","bk_letterfromllaalam2","bk_letterfromgadayn","bk_leaflet_false","bk_telvanni_vault_ledger","bk_yagrum's_book","bk_lustyargonianmaid","bk_alchemistsformulary","bk_secretsdwemeranimunculi","bk_fellowshiptemple","bk_formygodsandemperor","bk_ordolegionis","bk_bartendersguide_01","bookskill_mystery5","bk_notetotelvon","bk_warofthefirstcouncil","bk_onmorrowind","bk_realnerevar","bk_nerevarmoonandstar","bk_saintnerevar","bk_shorthistorymorrowind","bk_falljournal_unique","bookskill_alchemy1","bookskill_speechcraft2","bk_livesofthesaints","bk_saryonissermons","bk_mysteriousakavir","bk_firmament","bk_tamrielicreligions","bk_easternprovincesimpartial","bk_houseoftroubles_c","bk_legionsofthedead","bk_graspingfortune","bk_consolationsofprayer","bk_bookdawnanddusk","bk_anticipations","bk_ancestorsandthedunmer","bk_annotatedanuad","bk_childrensanuad","bk_arcturianheresy","bk_childrenofthesky","bk_chroniclesnchuleft","bk_bookofdaedra","bk_bartendersguide","bk_yagrum's_book","bk_alchemistsformulary","bk_commontongue","bk_commontongue_irano","bk_irano_note","bk_alen_note","writ_berano","writ_hloggar","writ_alen","bk_playscript","bk_ahnia","bk_nermarcnotes","bk_custom_armor","book_dwe_pipe00","book_dwe_cogs00","book_dwe_mach00","book_dwe_water00","book_dwe_power_con00","book_dwe_metal_fab00","bk_teran_invoice","book_dwe_boom00","bk_diary_sailor","bk_dbcontract","bk_adren","bk_suicidenote","bk_artifacts_tamriel"
		},
		customRecordType = "book", -- This will insert selected the specified custom record type into the pouch.
		customRecordRequiresEnchantment = false -- If this line does not exist at all, it will completely ignore this check.
												-- If this line exists and is true, the custom record requires an enchantment in order to be deposited. (Example: enchanted scrolls.)
												-- If this line exists and is false, the custom record must NOT have an enchantment in order to be deposited. (Example: Books.)
												
	}
}



--==----==----==----==----==----==----==--
--										--
--    DO NOT EDIT PAST THIS POINT!      --
-- (Unless you know what you're doing.) --
--										--
--==----==----==----==----==----==----==--

-- Create the ingredient pouch on server startup:
local function createRecord()
	
	local letsSave = false
	local recordStore = RecordStores["miscellaneous"]
	
	for pouchRef,pouchData in pairs(pouchConfig) do
		recordStore.data.permanentRecords[pouchRef] = {
			name = pouchData.pouchName,
			weight = pouchData.pouchWeight,
			icon = pouchData.pouchIcon,
			model = pouchData.pouchModel,
			value = pouchData.pouchValue,
			script = ""
		}
		letsSave = true
	end
	
	if letsSave then
		recordStore:Save()
	end
end

local Save = function(dbName, data)
	jsonInterface.save("custom/"..dbName..".json", data)
end

local loadAllPouchDBs = function()
	for refId,pouchData in pairs(pouchConfig) do
		
		local targetDB = jsonInterface.load("custom/"..pouchData.pouchDB..".json")
		
		if targetDB == nil then
			targetDB = {}
			targetDB.player = {}
			Save(pouchData.pouchDB, targetDB)
		end
		
	end
end

local function OnServerPostInit(eventStatus)
	createRecord()
	loadAllPouchDBs()
end
customEventHooks.registerHandler("OnServerPostInit", OnServerPostInit)


local getRecordTypeByRecordId = function(recordId)

    local isGenerated = logicHandler.IsGeneratedRecord(recordId)

    if isGenerated then
        local recordType = string.match(recordId, "_(%a+)_")

        if RecordStores[recordType] ~= nil then
            return recordType
        end
    end

    for _, storeType in pairs(config.recordStoreLoadOrder) do

        if isGenerated and RecordStores[storeType].data.generatedRecords[recordId] ~= nil then
            return storeType
        elseif RecordStores[storeType].data.permanentRecords[recordId] ~= nil then
            return storeType
        end
    end

    return nil
end

local isPermanentRecord = function(recordId)

    if recordId ~= nil and config.recordStoreLoadOrder ~= nil then
        for _, storeType in pairs(config.recordStoreLoadOrder) do
            if RecordStores[storeType].data.permanentRecords[recordId] ~= nil then
                return true
            end
        end
    end
    
    return false
end

--pouchItemAdd(pid, refId, count, soul, charge, enchantmentCharge)
pouchItemAdd = function(pid, refId, count, soul, charge, enchantmentCharge)
	
	Players[pid].data.customVariables.allowAddItem = true -- This allows the player to bypass the block enforced within morePlayerFuncs.lua's Player:SaveInventory()
	
	if refId == nil then return end
	if count == nil then count = 1 end
	if soul == nil then soul = "" end
	if charge == nil then charge = -1 end
	if enchantmentCharge == nil then enchantmentCharge = -1 end
	
	if refId == "gold_005" or refId == "gold_010" or refId == "gold_025" or refId == "gold_100" then
		refId = "gold_001"
	end
	
	if logicHandler.IsGeneratedRecord(refId) then
		local cellDescription = tes3mp.GetCell(pid)
        local cell = LoadedCells[cellDescription]
		local recordType = getRecordTypeByRecordId(refId)
		if RecordStores[recordType] ~= nil and cell ~= nil then
			local recordStore = RecordStores[recordType]
			for _, visitorPid in pairs(cell.visitors) do
				recordStore:LoadGeneratedRecords(visitorPid, recordStore.data.generatedRecords, {refId})
			end
		end
	end
	
	tes3mp.ClearInventoryChanges(pid)
	tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
	tes3mp.AddItemChange(pid, refId, count, charge, enchantmentCharge, soul)
	tes3mp.SendInventoryChanges(pid)
	Players[pid]:SaveInventory()
end

--pouchItemRemove(pid, refId, count, soul, charge, enchantmentCharge)
pouchItemRemove = function(pid, refId, count, soul, charge, enchantmentCharge)
	if pid == nil then return end
	if refId == nil then return end
	if count == nil then count = 1 end
	if soul == nil then soul = "" end
	if charge == nil then charge = -1 end
	if enchantmentCharge == nil then enchantmentCharge = -1 end
	
	if refId == "gold_005" or refId == "gold_010" or refId == "gold_025" or refId == "gold_100" then
		refId = "gold_001"
	end
	
	tes3mp.ClearInventoryChanges(pid)
	tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.REMOVE)
	tes3mp.AddItemChange(pid, refId, count, charge, enchantmentCharge, soul)
	tes3mp.SendInventoryChanges(pid)
	Players[pid]:SaveInventory()
	
	-- If it's generated, make sure it remains linked with the player so it isnt accidentally deleted by the server:
	if logicHandler.IsGeneratedRecord(refId) then
		local recordType = getRecordTypeByRecordId(refId)
		Players[pid]:AddLinkToRecord(recordType, refId)
	end
end

----------------------------------------------------------------------------------------------------------

local pName = function(pid)
	return Players[pid].name:lower()	
end

pouches.isPlayerInDB = function(pid, dbName)
	local name = Players[pid].name:lower()
	if name ~= nil and dbName ~= nil then
		local targetDB = jsonInterface.load("custom/"..dbName..".json")
		
		if targetDB.player[name] == nil then
			targetDB.player[name] = {}
			targetDB.player[name].count = 0
			targetDB.player[name].items = {}
			Save(dbName, targetDB)
		end
	end
end

pouches.deletePlayerFromDB = function(pid, dbName)
	local name = Players[pid].name:lower()
	if name ~= nil then
		if dbName ~= nil then
			local targetDB = jsonInterface.load("custom/"..dbName..".json")
			targetDB.player[name] = nil
			Save(dbName, targetDB)
			
		else
			for refId,pouchData in pairs(pouchConfig) do
				local targetDB = jsonInterface.load("custom/"..pouchData.pouchDB..".json")
				if targetDB ~= nil then
					targetDB.player[name] = nil
					Save(pouchData.pouchDB, targetDB)
				end
			end
		end
	end
end


-- Main Pouch Menu:
pouches.pouchUsedMenu = function(pid, pouchRefId)
	for refId,pouchData in pairs(pouchConfig) do
		if refId:lower() == pouchRefId:lower() then
			
			local name = pName(pid)
			if name == nil then break end
			
			pouches.isPlayerInDB(pid, pouchData.pouchDB)
			
			local currentStoredAmount = 0
			
			local targetDB = jsonInterface.load("custom/"..pouchData.pouchDB..".json")
			if targetDB.player[name] ~= nil and targetDB.player[name].items ~= nil and targetDB.player[name].count ~= nil then
				currentStoredAmount = targetDB.player[name].count
			end
			
			local namingScheme = pouchData.contentsNamePlural
			if currentStoredAmount ~= nil and currentStoredAmount == 1 then
				namingScheme = pouchData.contentsName
			end
			local menuMessage = color.Orange..pouchData.contentsName.." Pouch Menu\n\n\n"..pouchMsgColor.. 
				"Your "..color.Yellow..pouchData.contentsName..pouchMsgColor.." pouch is currently holding "..color.White..currentStoredAmount..pouchMsgColor.." "..namingScheme..".\n\n"..
				"What would you like to do?\n"
			local options = "Add "..pouchData.contentsNamePlural.." to Pouch;Withdraw from Pouch;Exit"
			
			return tes3mp.CustomMessageBox(pid, pouchData.pouchGUID, menuMessage, options)
		end
	end
end

-- Deposit items into pouch:
pouches.fillItemPouch = function(pid, pouchRefId)
	
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and pouchRefId ~= nil then
		
		local name = pName(pid)
		if name ~= nil then
			logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerControls")
			logicHandler.RunConsoleCommandOnPlayer(pid, "tm")
			
			local triggerSave = false
			local depositAmount = 0
			local pInv = Players[pid].data.inventory
			local pouchData = pouchConfig[pouchRefId]
			local targetDB = jsonInterface.load("custom/"..pouchData.pouchDB..".json")
			
			for item,_ in pairs(pInv) do
				local iRefId = pInv[item].refId
				if tableHelper.containsValue(pouchData.allowedRefIds, iRefId:lower()) then
					local giveAmount = Players[pid].data.inventory[item].count
					depositAmount = depositAmount + giveAmount
					
					if targetDB.player[name].items[iRefId] ~= nil then
						targetDB.player[name].items[iRefId] = (giveAmount + targetDB.player[name].items[iRefId])
					else
						targetDB.player[name].items[iRefId] = giveAmount
					end
					
					targetDB.player[name].count = (giveAmount + targetDB.player[name].count)
					pouchItemRemove(pid, iRefId, giveAmount)
					triggerSave = true
				end
				
				-- If customRecordPrefix is attached to the pouchData:
				if pouchData.customRecordPrefix ~= nil and pouchData.customRecordPrefix ~= "" then
					if string.match(iRefId, pouchData.customRecordPrefix) then
						local giveAmount = Players[pid].data.inventory[item].count
						depositAmount = depositAmount + giveAmount
						if targetDB.player[name].items[iRefId] ~= nil then
							targetDB.player[name].items[iRefId] = (giveAmount + targetDB.player[name].items[iRefId])
						else
							targetDB.player[name].items[iRefId] = giveAmount
						end
						targetDB.player[name].count = (giveAmount + targetDB.player[name].count)
						pouchItemRemove(pid, iRefId, giveAmount)
						triggerSave = true
					end
				end
				
				-- If customRecordType is attached to the pouchData:
				if pouchData.customRecordType ~= nil and pouchData.customRecordType ~= "" then
					
					local isGenerated = logicHandler.IsGeneratedRecord(iRefId)
					local isPermanent = isPermanentRecord(iRefId)
					
					if isGenerated or isPermanent then
						
						local requiresEnchantment = pouchData.customRecordRequiresEnchantment
						
						if Players[pid].data.inventory[item] ~= nil then
							local storeType = pouchData.customRecordType
							local recordType = RecordStores[storeType].data
							
							local giveAmount
							
							if isGenerated and recordType.generatedRecords[iRefId] ~= nil then
								
								if requiresEnchantment == nil then
									giveAmount = Players[pid].data.inventory[item].count
								elseif requiresEnchantment == true and recordType.generatedRecords[iRefId].enchantmentId ~= nil and recordType.generatedRecords[iRefId].enchantmentId ~= "" then
									giveAmount = Players[pid].data.inventory[item].count
								elseif requiresEnchantment == false and (recordType.generatedRecords[iRefId].enchantmentId == nil or recordType.generatedRecords[iRefId].enchantmentId == "") then
									giveAmount = Players[pid].data.inventory[item].count
								end
								
							elseif recordType.permanentRecords[iRefId] ~= nil then
								
								if requiresEnchantment == nil then
									giveAmount = Players[pid].data.inventory[item].count
								elseif requiresEnchantment == true and recordType.permanentRecords[iRefId].enchantmentId ~= nil and recordType.permanentRecords[iRefId].enchantmentId ~= "" then
									giveAmount = Players[pid].data.inventory[item].count
								elseif requiresEnchantment == false and (recordType.permanentRecords[iRefId].enchantmentId == nil or recordType.permanentRecords[iRefId].enchantmentId == "") then
									giveAmount = Players[pid].data.inventory[item].count
								end
								
							end
							
							if giveAmount ~= nil then
								
								depositAmount = depositAmount + giveAmount
								
								if targetDB.player[name].items[iRefId] ~= nil then
									targetDB.player[name].items[iRefId] = (giveAmount + targetDB.player[name].items[iRefId])
								else
									targetDB.player[name].items[iRefId] = giveAmount
								end
								
								targetDB.player[name].count = (giveAmount + targetDB.player[name].count)
								pouchItemRemove(pid, iRefId, giveAmount)
								triggerSave = true
							end
							
						end
						
					end
					
				end
				
				
			end
			
			local namingScheme = pouchData.contentsNamePlural
			local msgTxt = "You have no "..namingScheme.."."
			
			if depositAmount > 0 then
				logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound \"Item Misc Up\"")
				if depositAmount == 1 then
					namingScheme = pouchData.contentsName
				end
				msgTxt = "You have deposited "..depositAmount.." "..namingScheme.."."
			end
			
			tes3mp.MessageBox(pid, -1, msgTxt)
			
			if triggerSave then
				Save(pouchData.pouchDB, targetDB)
			end
			
			logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerControls")
			logicHandler.RunConsoleCommandOnPlayer(pid, "tm")
		end
	end
end

-- Withdraw items from pouch:
pouches.emptyItemPouch = function(pid, pouchRefId)

	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and pouchRefId ~= nil then
		
		local name = pName(pid)
		if name ~= nil then
		
			local triggerSave = false
			local withdrawnAmount = 0
			
			local pouchData = pouchConfig[pouchRefId]
			local targetDB = jsonInterface.load("custom/"..pouchData.pouchDB..".json")
			
			local itemsToAdd = {}
			
			if targetDB.player[name] ~= nil and targetDB.player[name].items ~= nil then
				withdrawnAmount = targetDB.player[name].count
				for gRefId, gAmount in pairs(targetDB.player[name].items) do
					itemsToAdd[gRefId] = gAmount
					targetDB.player[name].items[gRefId] = nil
					triggerSave = true
				end
				targetDB.player[name].count = 0
			end
			
			if not tableHelper.isEmpty(itemsToAdd) then
				for tRef, tAmount in pairs(itemsToAdd) do
					pouchItemAdd(pid, tRef, tAmount)
				end
			end
			
			local msgTxt = "Your "..pouchData.contentsName.." pouch is empty."
			
			if withdrawnAmount > 0 then
				logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound \"Item Misc Up\"")
				local namingScheme = pouchData.contentsNamePlural
				if withdrawnAmount == 1 then
					namingScheme = pouchData.contentsName
				end
				msgTxt = "You have withdrawn "..withdrawnAmount.." "..namingScheme.."."
			end
			
			tes3mp.MessageBox(pid, -1, msgTxt)
			
			if triggerSave then
				--tes3mp.LogMessage(enumerations.log.INFO, "[Pouch]: \""..string.lower(Players[pid].accountName).."\" withdrew "..withdrawnAmount.." gems from a pouch.")
				Save(pouchData.pouchDB, targetDB)
			end
		end
	end
end

-- Pouch GUI Actions:
customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	
	for pouchRefId,pouchData in pairs(pouchConfig) do
		if idGui == pouchData.pouchGUID then
			if tonumber(data) == 0 then -- Add items to Pouch
				pouches.fillItemPouch(pid, pouchRefId)
			elseif tonumber(data) == 1 then -- Withdraw from Pouch
				pouches.emptyItemPouch(pid, pouchRefId)
				--gemPouch.gemPouchUsedMenu(pid)
			else -- Exit
				return
			end
		end
	end
end)

-- Do something when item is used:
pouches.OnPlayerItemUseValidator = function(eventStatus, pid, itemRefId)
	for refId,pouchData in pairs(pouchConfig) do
		if refId:lower() == itemRefId:lower() then
			pouches.pouchUsedMenu(pid, itemRefId)
			--return customEventHooks.makeEventStatus(nil,nil)
		end
	end
end
customEventHooks.registerValidator("OnPlayerItemUse",pouches.OnPlayerItemUseValidator)

local loginFunction = function(pid)
	
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		local name = Players[pid].name:lower()
		if name ~= nil then
			
			for pouchRef,pouchData in pairs(pouchConfig) do
				
				local patronTier = pouchData.patreonTierRequired
				if giveEveryPlayerPouchesOnLogin == true then
					local dbName = pouchData.pouchDB
					if name ~= nil and dbName ~= nil then
					
						local targetDB = jsonInterface.load("custom/"..dbName..".json")
						if targetDB.player[name] == nil then
							local pouchRefId = string.lower(pouchRef)
							if not inventoryHelper.containsItem(Players[pid].data.inventory, pouchRefId) then
								
								tes3mp.MessageBox(pid, -1, pouchData.pouchName.." has been added to your inventory.")
								pouchItemAdd(pid, pouchRefId, 1)
							end
							pouches.isPlayerInDB(pid, dbName)
						end
					
					end
				end
			end
			
		end
		
	end
end

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	loginFunction(pid)
end)

return pouches