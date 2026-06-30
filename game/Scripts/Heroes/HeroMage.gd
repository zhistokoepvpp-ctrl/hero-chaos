extends HeroBase

func _init():
	hero_type = Constants.HeroType.MAGE
	cooldown_q_max = 7.0
	cooldown_w_max = 15.0
	mana_cost_q = 40
	mana_cost_w = 60

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
