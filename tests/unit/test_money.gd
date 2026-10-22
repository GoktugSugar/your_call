extends GutTest
## The money chapter: the wallet, the shop, the cigarette auction, the buyback and the receipt.

const SHOP_SCENE := "res://stages/shop/shop_stage.tscn"
const AUCTION_SCENE := "res://stages/auction/auction_stage.tscn"
const BUYBACK_SCENE := "res://stages/buyback/buyback_stage.tscn"
const RECEIPT_SCENE := "res://stages/receipt/receipt_stage.tscn"


func test_buying_spends_from_the_wallet_and_keeps_the_thing() -> void:
	var wallet := Wallet.new(10000)
	wallet.buy(Purchase.make(&"charisma", "Charisma", "charisma_figure", 3500))
	assert_eq(wallet.balance, 6500)
	assert_eq(wallet.bought.size(), 1)
	assert_eq(wallet.spent(), 3500)
	assert_almost_eq(wallet.share_left(), 0.65, 0.001)


func test_buying_more_of_a_thing_adds_to_it() -> void:
	var wallet := Wallet.new(10000)
	wallet.buy(Purchase.make(&"years", "A stranger's years", "stranger_clock", 700))
	wallet.buy(Purchase.make(&"years", "A stranger's years", "stranger_clock", 800))
	assert_eq(wallet.bought.size(), 1)
	assert_eq(wallet.bought[0].units, 2)
	assert_eq(wallet.bought[0].paid, 1500)


func test_selling_back_returns_the_money_and_forgets_the_thing() -> void:
	var wallet := Wallet.new(10000)
	var item := Purchase.make(&"charisma", "Charisma", "charisma_figure", 3500)
	wallet.buy(item)
	wallet.sell(item, 1750)
	assert_eq(wallet.balance, 8250)
	assert_eq(wallet.bought.size(), 0)
	assert_eq(wallet.spent(), 1750)


func test_a_wallet_says_when_its_balance_changes() -> void:
	var wallet := Wallet.new(100)
	watch_signals(wallet)
	wallet.buy(Purchase.make(&"cucumber", "The cucumber", "cucumber", 100))
	assert_signal_emitted_with_parameters(wallet, "changed", [0])


func test_the_shop_sells_the_thing_when_there_is_the_money() -> void:
	var stage := _shop({"price": 1800})
	assert_eq(await stage.play_consequence(0), &"bought")
	assert_eq(stage.run.wallet.balance, 8200)
	assert_eq(stage.reveal_split(0).pick, 0)


func test_the_shop_will_not_sell_without_the_money() -> void:
	var stage := _shop({"price": 1800}, 1000)
	assert_eq(await stage.play_consequence(0), &"broke")
	assert_eq(stage.run.wallet.balance, 1000)
	assert_eq(stage.run.wallet.passed.size(), 1)
	assert_eq(stage.reveal_split(0).pick, 1, "trying without the money counts as keeping it")


func test_keeping_the_money_passes_the_thing_by() -> void:
	var stage := _shop({"price": 1800})
	assert_eq(await stage.play_consequence(1), &"passed")
	assert_eq(stage.run.wallet.passed.size(), 1)
	assert_eq(stage.run.wallet.balance, 10000)


func test_a_price_of_everything_asks_for_the_whole_balance() -> void:
	var stage := _shop({"price": "everything", "buyback": 100}, 7000)
	assert_eq(stage.fills()["price"], "$7,000")
	await stage.play_consequence(0)
	assert_eq(stage.run.wallet.balance, 0)
	assert_eq(stage.run.wallet.bought[0].buyback_share, 100.0)


func test_the_shop_fills_its_price() -> void:
	var stage := _shop({"price": 1800})
	assert_eq(stage.fills()["price"], "$1,800")
	stage.question.ask.append(LineData.make("ch3.thing.ask.1", "[amber]{price}[/amber]."))
	var variants := ShopStage.fill_variants(stage.question)
	assert_eq(variants.size(), 1)
	assert_eq(variants.values()[0][0]["keys"]["price"], "1800")


func test_a_thing_bought_one_at_a_time_comes_round_again_dearer() -> void:
	var stage := _shop({"price": 700, "step": 100, "most": 40}, 2000)
	assert_eq(await stage.play_consequence(0), &"first")
	assert_true(stage.another_round())
	assert_eq(stage.fills()["price"], "$800")
	assert_eq(await stage.play_consequence(0), &"more")
	assert_eq(await stage.play_consequence(0), &"ran_out", "the third would cost 900 with 500 left")
	assert_false(stage.another_round())
	assert_eq(stage.run.wallet.bought[0].units, 2)


func test_stopping_after_buying_some_is_some_and_after_none_is_none() -> void:
	var some := _shop({"price": 700, "step": 100}, 2000)
	await some.play_consequence(0)
	assert_eq(await some.play_consequence(1), &"some")
	assert_eq(some.reveal_split(1).pick, 0)
	var none := _shop({"price": 700, "step": 100}, 2000)
	assert_eq(await none.play_consequence(1), &"none")
	assert_eq(none.reveal_split(1).pick, 1)


func test_the_auction_brings_the_rival_in_and_turns_its_labels_into_bids() -> void:
	var stage := _auction()
	assert_eq(stage.option_labels(), PackedStringArray(["Buy them", "Pass"]))
	assert_eq(await stage.play_consequence(0), &"auction")
	assert_true(stage.another_round())
	assert_eq(stage.fills()["rival"], "$30")
	assert_eq(stage.option_labels(), PackedStringArray(["Bid $40", "Drop out"]))
	assert_true(stage.run.remembers(RunState.BUTTON_AUCTIONED))


func test_bidding_past_all_sense_curses_and_no_money_moves() -> void:
	var stage := _auction()
	await stage.play_consequence(0)
	assert_eq(await stage.play_consequence(0), &"bid")
	assert_eq(stage.fills()["rival"], "$50")
	assert_eq(await stage.play_consequence(0), &"cursed")
	assert_eq(stage.run.wallet.balance, 10000)


func test_dropping_out_lets_the_rival_win_and_still_went_for_it() -> void:
	var stage := _auction()
	await stage.play_consequence(0)
	assert_eq(await stage.play_consequence(1), &"dropped")
	assert_false(stage.another_round())
	assert_eq(stage.reveal_split(1).pick, 0)


func test_without_twenty_dollars_there_is_no_auction() -> void:
	var stage := _auction(10)
	assert_eq(await stage.play_consequence(0), &"broke")
	assert_false(stage.another_round())
	assert_eq(stage.reveal_split(0).pick, 1)


func test_the_auction_lists_each_round_s_bid_for_its_lines() -> void:
	var question := _auction().question
	var variants := AuctionStage.fill_variants(question)
	var taunts := question.lines_in(&"taunts")
	assert_eq(variants[taunts[0].id][0]["keys"]["rival"], "30")
	assert_eq(variants[taunts[1].id][0]["keys"]["rival"], "50")
	var bid := question.options[0].reactions[&"bid"][0] as LineData
	assert_eq(variants[bid.id].size(), 1)
	assert_eq(variants[bid.id][0]["keys"]["rival"], "50")


func test_the_buyback_offers_half_rounded_and_the_whole_for_its_own_share() -> void:
	var data := {"share": 50, "round_to": 10, "least": 10}
	assert_eq(BuybackStage.offer_for(Purchase.make(&"a", "", "", 1800), data), 900)
	assert_eq(BuybackStage.offer_for(Purchase.make(&"a", "", "", 3500), data), 1750)
	assert_eq(BuybackStage.offer_for(Purchase.make(&"a", "", "", 4), data), 10)
	var poverty := Purchase.make(&"poverty", "End Poverty", "charity_hand", 10000)
	poverty.buyback_share = 100.0
	assert_eq(BuybackStage.offer_for(poverty, data), 10000)


func test_owning_nothing_there_is_nothing_to_choose() -> void:
	var stage := _buyback([])
	assert_eq(stage.ask_key(), &"nothing")
	assert_false(stage.offers_choice())


func test_the_buyback_walks_the_rows_in_order() -> void:
	var stage := _buyback([Purchase.make(&"luck", "The Good Luck", "clover", 3000),
			Purchase.make(&"iq", "Ten More IQ", "iq_head", 2500), Purchase.make(&"pain", "No More Pain", "plaster", 4500)])
	assert_eq(stage.ask_key(), &"items")
	assert_eq(await stage.play_consequence(1), &"kept")
	assert_eq(await stage.play_consequence(0), &"sold")
	assert_eq(stage.run.wallet.balance, 1250)
	assert_true(stage.another_round())
	assert_eq(await stage.play_consequence(1), &"last")
	assert_false(stage.another_round())
	assert_eq(stage.reveal_split(1).pick, 0, "something was sold back")


func test_keeping_everything_ends_on_none() -> void:
	var stage := _buyback([Purchase.make(&"luck", "The Good Luck", "clover", 3000)])
	assert_eq(await stage.play_consequence(1), &"none")
	assert_eq(stage.reveal_split(1).pick, 1)


func test_a_thing_with_its_own_lines_is_asked_and_answered_by_its_id() -> void:
	var poverty := Purchase.make(&"poverty", "End Poverty", "charity_hand", 10000)
	poverty.buyback_share = 100.0
	var stage := _buyback([poverty])
	assert_eq(stage.ask_key(), &"poverty")
	assert_eq(await stage.play_consequence(0), &"poverty")
	assert_eq(stage.run.wallet.balance, 10000)


func test_the_receipt_reads_the_share_left_and_nudges_by_it() -> void:
	assert_eq(await _receipt(9000).play_consequence(-1), &"hoard")
	assert_eq(await _receipt(1000).play_consequence(-1), &"spend")
	var middle := _receipt(5000)
	assert_eq(await middle.play_consequence(-1), &"middle")
	assert_almost_eq(middle.run.profile.leanings[&"self_others"], -0.1, 0.0001)


func test_the_loader_reads_nudges_keyed_by_outcome() -> void:
	var loader := ContentLoader.new(PackedStringArray(["self_others"]))
	var option := loader._option({"id": "buy", "label": "Buy it", "crowd": 50,
			"profile": {"self_others": -0.05, "broke": {"self_others": 0.03}, "bid": {}},
			"reaction": ["Bought."]}, "ch3.x", "here")
	assert_eq(loader.problems, PackedStringArray())
	assert_eq(option.profile_for(&"bought"), {&"self_others": -0.05})
	assert_eq(option.profile_for(&"broke"), {&"self_others": 0.03})
	assert_eq(option.profile_for(&"bid"), {})


## A shop in the tree for a thing with [param stage_data], shopping from [param balance].
func _shop(stage_data: Dictionary, balance := 10000) -> ShopStage:
	var data := {"type": "shop", "item": "no_such_doodle", "label": "A thing"}
	data.merge(stage_data, true)
	var stage := _staged(SHOP_SCENE, _question(data, ["Buy it", "Keep the money"], [{"buy": true}, {}]), balance) as ShopStage
	return stage


func _auction(balance := 10000) -> AuctionStage:
	var data := {"type": "auction", "item": "no_such_doodle", "price": 20, "step": 10, "persist": 3,
			"bid": {"label": "Bid {bid}"}, "drop": {"label": "Drop out"}}
	var question := _question(data, ["Buy them", "Pass"], [{"buy": true}, {}])
	var taunts: Array[LineData] = [LineData.make("ch3.cigarettes.taunts.1", "{rival}! Easy.", &"button"),
			LineData.make("ch3.cigarettes.taunts.2", "{rival}. No wallet.", &"button")]
	question.line_sets[&"taunts"] = taunts
	var bid: Array[LineData] = [LineData.make("ch3.cigarettes.buy.bid.1", "It bids {rival}.")]
	question.options[0].reactions[&"bid"] = bid
	var stage := (load(AUCTION_SCENE) as PackedScene).instantiate() as AuctionStage
	stage.walker_scene = null
	return _ready_stage(stage, question, balance) as AuctionStage


func _buyback(owned: Array) -> BuybackStage:
	var question := _question({"type": "buyback", "share": 50, "round_to": 10, "least": 10},
			["Sell it back", "Keep it"], [{"sell": true}, {}])
	var said: Array[LineData] = [LineData.make("x", "Back it comes.")]
	question.options[0].reactions[&"poverty"] = said
	question.options[1].reactions[&"poverty"] = said
	question.asks[&"poverty"] = said
	var run := RunState.new()
	var wallet := run.open_wallet(10000)
	for item: Purchase in owned:
		wallet.buy(item)
	var stage := (load(BUYBACK_SCENE) as PackedScene).instantiate() as BuybackStage
	stage.run = run
	_quicken(stage)
	add_child_autofree(stage)
	stage.setup(question)
	return stage


func _receipt(balance: int) -> ReceiptStage:
	var question := QuestionData.new()
	question.id = &"receipt"
	question.stage = {"type": "receipt", "hoard_from": 80, "spend_upto": 20, "nudge": {"self_others": -0.2}}
	var stage := _staged(RECEIPT_SCENE, question, 10000) as ReceiptStage
	stage.run.wallet.balance = balance
	return stage


func _staged(scene_path: String, question: QuestionData, balance: int) -> Stage:
	var stage := (load(scene_path) as PackedScene).instantiate() as Stage
	return _ready_stage(stage, question, balance)


## [param stage] in the tree with a wallet holding [param balance], quick in everything it does.
func _ready_stage(stage: Stage, question: QuestionData, balance: int) -> Stage:
	var run := RunState.new()
	run.open_wallet(balance)
	stage.run = run
	_quicken(stage)
	add_child_autofree(stage)
	stage.setup(question)
	return stage


## Turns every pause and motion a stage has down to almost nothing, so tests do not wait on them.
func _quicken(stage: Stage) -> void:
	for property: String in ["loop_duration", "hop_duration", "fade_duration", "shake_time", "light_duration",
			"sold_fade", "slip_duration", "line_fade", "grab_duration"]:
		if property in stage:
			stage.set(property, 0.02)
	for property: String in ["hold_duration", "line_gap", "beat"]:
		if property in stage:
			stage.set(property, 0.0)


func _question(stage_data: Dictionary, labels: Array, outcomes: Array) -> QuestionData:
	var question := QuestionData.new()
	question.id = &"thing"
	question.stage = stage_data
	for i in labels.size():
		var option := OptionData.new()
		option.id = StringName("option_%d" % i)
		option.label = labels[i]
		option.outcome = outcomes[i]
		option.crowd = 50.0
		question.options.append(option)
	return question
