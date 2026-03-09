extends Node

func _ready() -> void:
	print("=== Ascend the Void – Boot Test ===")

	# ── Test 1: start_new_run with fixed seed ──
	GameManager.start_new_run("rift_walker", 12345)
	assert(GameManager.is_run_active, "FAIL: run should be active")
	assert(GameManager.run_seed == 12345, "FAIL: seed mismatch")
	assert(GameManager.deck.size() > 0, "FAIL: starter deck is empty")
	print("PASS – starter deck has %d cards: %s" % [GameManager.deck.size(), str(GameManager.deck)])

	# ── Test 2: deterministic RNG ──
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 12345
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 12345
	for i in range(10):
		assert(rng_a.randi() == rng_b.randi(), "FAIL: RNG not deterministic at step %d" % i)
	print("PASS – RNG is deterministic for seed 12345")

	# ── Test 3: save / load round-trip ──
	SaveSystem.save_run()
	assert(SaveSystem.has_save(), "FAIL: save file not found after save_run()")
	var original_deck := GameManager.deck.duplicate()
	var original_gold := GameManager.gold
	var original_hp   := GameManager.current_hp

	GameManager.deck = []
	GameManager.gold = 0
	GameManager.current_hp = 0

	var loaded := SaveSystem.load_run()
	assert(loaded, "FAIL: load_run() returned false")
	assert(GameManager.deck == original_deck, "FAIL: deck mismatch after load")
	assert(GameManager.gold == original_gold, "FAIL: gold mismatch after load")
	assert(GameManager.current_hp == original_hp, "FAIL: hp mismatch after load")
	print("PASS – save/load round-trip verified")

	# ── Test 4: gold / HP mutation ──
	GameManager.modify_gold(-20)
	assert(GameManager.gold == original_gold - 20, "FAIL: gold subtraction")
	GameManager.modify_gold(50)
	assert(GameManager.gold == original_gold + 30, "FAIL: gold addition")
	GameManager.modify_hp(-999)
	assert(GameManager.current_hp == 0, "FAIL: hp should clamp to 0")
	print("PASS – gold and HP mutations correct")

	SaveSystem.clear_run_save()
	print("=== ALL TESTS PASSED – Prompt 1 gate cleared ===")
