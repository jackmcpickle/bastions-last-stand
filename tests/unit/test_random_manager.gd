extends GutTest

## Unit tests for RandomManager


# ============================================
# Seed tests
# ============================================

func test_same_seed_same_sequence() -> void:
	var rng1 := RandomManager.new(12345)
	var rng2 := RandomManager.new(12345)

	var seq1 := []
	var seq2 := []

	for i in range(10):
		seq1.append(rng1.randi_range(0, 100))
		seq2.append(rng2.randi_range(0, 100))

	assert_eq(seq1, seq2)


func test_different_seed_different_sequence() -> void:
	var rng1 := RandomManager.new(12345)
	var rng2 := RandomManager.new(54321)

	var seq1 := []
	var seq2 := []

	for i in range(10):
		seq1.append(rng1.randi_range(0, 100))
		seq2.append(rng2.randi_range(0, 100))

	assert_ne(seq1, seq2)


func test_set_seed_resets_sequence() -> void:
	var rng := RandomManager.new(12345)
	var first := rng.randi_range(0, 100)

	rng.set_seed(12345)
	var second := rng.randi_range(0, 100)

	assert_eq(first, second)


func test_get_seed() -> void:
	var rng := RandomManager.new(99999)

	assert_eq(rng.get_seed(), 99999)


# ============================================
# Call count tests
# ============================================

func test_call_count_increments() -> void:
	var rng := RandomManager.new(0)

	assert_eq(rng.get_call_count(), 0)

	rng.randi_range(0, 10)
	assert_eq(rng.get_call_count(), 1)

	rng.randf()
	assert_eq(rng.get_call_count(), 2)


func test_call_count_resets_on_set_seed() -> void:
	var rng := RandomManager.new(0)
	rng.randi_range(0, 10)
	rng.randi_range(0, 10)

	rng.set_seed(0)

	assert_eq(rng.get_call_count(), 0)


# ============================================
# randi_range() tests
# ============================================

func test_randi_range_inclusive() -> void:
	var rng := RandomManager.new(0)

	var has_min := false
	var has_max := false

	for i in range(1000):
		var val := rng.randi_range(0, 10)
		if val == 0:
			has_min = true
		if val == 10:
			has_max = true

	assert_true(has_min, "Min value never generated")
	assert_true(has_max, "Max value never generated")


func test_randi_range_bounds() -> void:
	var rng := RandomManager.new(0)

	for i in range(100):
		var val := rng.randi_range(5, 15)
		assert_gte(val, 5)
		assert_lte(val, 15)


# ============================================
# randi_range_exclusive() tests
# ============================================

func test_randi_range_exclusive_bounds() -> void:
	var rng := RandomManager.new(0)

	for i in range(100):
		var val := rng.randi_range_exclusive(10)
		assert_gte(val, 0)
		assert_lt(val, 10)


func test_randi_range_exclusive_never_max() -> void:
	var rng := RandomManager.new(0)

	for i in range(1000):
		var val := rng.randi_range_exclusive(5)
		assert_lt(val, 5)


# ============================================
# randf() tests
# ============================================

func test_randf_bounds() -> void:
	var rng := RandomManager.new(0)

	for i in range(100):
		var val := rng.randf()
		assert_gte(val, 0.0)
		assert_lt(val, 1.0)


# ============================================
# randf_range() tests
# ============================================

func test_randf_range_bounds() -> void:
	var rng := RandomManager.new(0)

	for i in range(100):
		var val := rng.randf_range(5.0, 10.0)
		assert_gte(val, 5.0)
		assert_lte(val, 10.0)


# ============================================
# check_probability() tests
# ============================================

func test_check_probability_always_true() -> void:
	var rng := RandomManager.new(0)

	for i in range(100):
		assert_true(rng.check_probability(1000))  # 100%


func test_check_probability_always_false() -> void:
	var rng := RandomManager.new(0)

	for i in range(100):
		assert_false(rng.check_probability(0))  # 0%


func test_check_probability_roughly_correct() -> void:
	var rng := RandomManager.new(12345)
	var successes := 0
	var trials := 1000

	for i in range(trials):
		if rng.check_probability(500):  # 50%
			successes += 1

	# Should be roughly 50% (allow 10% variance)
	var rate := float(successes) / float(trials)
	assert_gt(rate, 0.4)
	assert_lt(rate, 0.6)


# ============================================
# shuffle() tests
# ============================================

func test_shuffle_changes_order() -> void:
	var rng := RandomManager.new(12345)
	var array := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var original := array.duplicate()

	rng.shuffle(array)

	assert_ne(array, original)


func test_shuffle_preserves_elements() -> void:
	var rng := RandomManager.new(0)
	var array := [1, 2, 3, 4, 5]

	rng.shuffle(array)

	assert_eq(array.size(), 5)
	assert_has(array, 1)
	assert_has(array, 2)
	assert_has(array, 3)
	assert_has(array, 4)
	assert_has(array, 5)


func test_shuffle_deterministic() -> void:
	var rng1 := RandomManager.new(99)
	var rng2 := RandomManager.new(99)
	var array1 := [1, 2, 3, 4, 5]
	var array2 := [1, 2, 3, 4, 5]

	rng1.shuffle(array1)
	rng2.shuffle(array2)

	assert_eq(array1, array2)


# ============================================
# pick() tests
# ============================================

func test_pick_returns_element() -> void:
	var rng := RandomManager.new(0)
	var array := ["a", "b", "c"]

	var picked := rng.pick(array)

	assert_has(array, picked)


func test_pick_empty_returns_null() -> void:
	var rng := RandomManager.new(0)
	var array := []

	var picked := rng.pick(array)

	assert_null(picked)


func test_pick_deterministic() -> void:
	var rng1 := RandomManager.new(42)
	var rng2 := RandomManager.new(42)
	var array := [1, 2, 3, 4, 5]

	assert_eq(rng1.pick(array), rng2.pick(array))


# ============================================
# pick_index() tests
# ============================================

func test_pick_index_valid() -> void:
	var rng := RandomManager.new(0)
	var array := [1, 2, 3, 4, 5]

	var idx := rng.pick_index(array)

	assert_gte(idx, 0)
	assert_lt(idx, array.size())


func test_pick_index_empty_returns_negative() -> void:
	var rng := RandomManager.new(0)
	var array := []

	var idx := rng.pick_index(array)

	assert_eq(idx, -1)


# ============================================
# create_child() tests
# ============================================

func test_create_child_different_from_parent() -> void:
	var parent := RandomManager.new(12345)
	var child := parent.create_child(1)

	var parent_val := parent.randi_range(0, 1000)
	var child_val := child.randi_range(0, 1000)

	assert_ne(parent_val, child_val)


func test_create_child_deterministic() -> void:
	var parent1 := RandomManager.new(12345)
	var parent2 := RandomManager.new(12345)

	var child1 := parent1.create_child(5)
	var child2 := parent2.create_child(5)

	assert_eq(child1.randi_range(0, 1000), child2.randi_range(0, 1000))


func test_create_child_different_ids_different_sequence() -> void:
	var parent := RandomManager.new(12345)

	var child1 := parent.create_child(1)
	var child2 := parent.create_child(2)

	assert_ne(child1.randi_range(0, 1000), child2.randi_range(0, 1000))
