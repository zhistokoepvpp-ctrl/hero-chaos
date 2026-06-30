extends HeroBase

func _init():
	hero_type = Constants.HeroType.NECROMANCER
	cooldown_q_max = 12.0
	cooldown_w_max = 8.0
	mana_cost_q = 45
	mana_cost_w = 30

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass
