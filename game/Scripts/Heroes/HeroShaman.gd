extends HeroBase

func _init():
	hero_type = Constants.HeroType.SHAMAN
	cooldown_q_max = 7.0
	cooldown_w_max = 14.0
	mana_cost_q = 35
	mana_cost_w = 55

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
