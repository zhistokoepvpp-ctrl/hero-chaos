extends HeroBase

func _init():
	hero_type = Constants.HeroType.ARCHER
	cooldown_q_max = 6.0
	cooldown_w_max = 10.0
	mana_cost_q = 25
	mana_cost_w = 40

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
