extends HeroBase

func _init():
	hero_type = Constants.HeroType.PALADIN
	cooldown_q_max = 10.0
	cooldown_w_max = 20.0
	mana_cost_q = 35
	mana_cost_w = 50

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
