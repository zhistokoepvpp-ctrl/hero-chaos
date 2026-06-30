extends HeroBase

func _init():
	hero_type = Constants.HeroType.WARRIOR
	cooldown_q_max = 8.0
	cooldown_w_max = 12.0
	mana_cost_q = 30
	mana_cost_w = 50

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
