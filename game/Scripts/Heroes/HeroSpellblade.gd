extends HeroBase

func _init():
	hero_type = Constants.HeroType.SPELLBLADE
	cooldown_q_max = 5.0
	cooldown_w_max = 10.0
	mana_cost_q = 30
	mana_cost_w = 45

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
