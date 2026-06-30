extends HeroBase

func _init():
	hero_type = Constants.HeroType.GUNSLINGER
	cooldown_q_max = 4.0
	cooldown_w_max = 10.0
	mana_cost_q = 20
	mana_cost_w = 35

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
