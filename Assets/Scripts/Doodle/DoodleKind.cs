namespace YourCall
{
    /// <summary>
    /// Which small hand-drawn ink doodle to draw for a would-you-rather option (see
    /// <see cref="InkDoodle"/> and docs/art-and-ui.md). Referenced from the data (a `Dilemma`'s two
    /// option doodles), so adding a new would-you-rather that reuses existing doodles is pure data.
    /// Adding a brand new doodle is a new value here plus its drawer in <see cref="InkDoodle"/>.
    /// </summary>
    public enum DoodleKind
    {
        None,
        TurdSwirl,      // a poop coiled like soft serve (the shit that tastes like ice cream)
        ConeSwirl,      // an ice cream cone with the same swirl (the ice cream that tastes like shit)
        WingedFigure,   // a little figure with wings (flight)
        FlexingFigure,  // a figure flexing a bicep (super strength)
        GiantDuck,      // one big duck (the size of a horse)
        TinyHorses,     // a little herd of tiny horses (the size of ducks)
        RewindButton,   // a round button with a rewind symbol
        PauseButton,    // a round button with a pause symbol
        Snowflake,      // a snowflake (always a little too cold)
        Sun,            // a sun (always a little too hot)
        ThirdArmFigure, // a stick figure with a third arm
        TwoHeadFigure,  // a stick figure with two heads

        // ---- Chapter 3 (the money): a coloured-outline doodle of each priceable thing ----
        Poverty,        // ending poverty: a cupped hand offering a small heart (charity), gold
        Burrito,        // free food for life, English: a wrapped burrito, warm
        Kebab,          // free food for life, Turkish: a skewer with chunks, warm (swaps with Burrito by language)
        Nose,           // a marginally less bad nose, pink
        Hourglass,      // one extra year of life, green (life / time)
        CigarettePack,  // the cigarette auction: a small pack with a few cigarettes, red
        Bandage,        // no more pain: a plaster / bandage, pink
        MemoryCloud,    // the deleted memory: a thought cloud with a scribble inside, purple
        StolenYears,    // bulk: a small stranger figure beside a clock (ten years of their life), red
        Forgetting,     // the cheap forgetting: a head with the memory drifting away, sky
        Tombstone,      // the truth about how you died: a headstone with a question mark, muted (superseded by QuestionMark)
        Coin,           // cash-out menu: a coin, gold (cash-out removed; kept for ordinal stability)
        Star,           // cash-out menu: a star (something meaningful), gold (cash-out removed; kept)
        Candy,          // cash-out menu: a wrapped sweet (cheap junk), pink (cash-out removed; kept)

        // ---- Chapter 3 rework: the ten double-edged items, the cucumber finale, and the plain question mark ----
        Charisma,       // everyone instantly likes you: a figure with radiating lines, warm
        OffSwitch,      // turn off one emotion at will: a head with a small switch
        PerfectMemory,  // never forget anything: a head with sharp, hard lines
        LieDetector,    // always know when you are lied to: an open eye
        Rewind,         // once ever, undo one life decision: a curved back-arrow
        IqUp,           // ten more IQ: a head with a small up-arrow
        NeverTired,     // never sleep or tire again: an eye held open over a crossed-out z
        Clover,         // the good luck: a four-leaf clover, green
        FeelNothing,    // never grief or joy at full volume: a flat-line mouth face
        InnerVoice,     // a wise voice always right: a head with a small speech curl
        Cucumber,       // the deadpan 100 dollar finale: a cucumber, green
        QuestionMark,   // the truth about how you died (reworked visual): just an ink question mark

        // ---- Chapter 3 would-you-rather breathers (three new pool pairs) ----
        Cat,            // the insulting cat (front facing, pointy ears, whiskers), purple
        Dog,            // the lying dog (side view, snout, floppy ear), brown
        Shirt,          // the never-staining shirt (a T-shirt), blue
        Shoe,           // the never-hurting shoes (a side sneaker), orange
        Wallet,         // the endless 20 (a bifold wallet with a note), green
        MoneyBag,       // one big win (a cinched sack with a dollar sign), gold

        // ---- Chapter 4 (the gun) would-you-rather breathers (three new pool pairs) ----
        Dragon,         // a pet dragon the size of a cat (a winged, snouted, tailed creature), purple
        Dinosaur,       // a pet dinosaur the size of a dog (a long-necked sauropod), green
        House,          // a house that walks (walls, roof, chimney, little legs), orange
        Car,            // a car that swims (a side-profile car with two wheels), blue
        Robot,          // a robot butler (a boxy figure with an antenna), sky
        Ghost,          // a ghost flatmate (a sheet ghost with eyes), purple

        // ---- Chapter 5 (Who Would Win): the polished coloured fighter doodles ----
        // Each is a clean, stylized, on-model coloured ink doodle readable at a glance at the side-by-side
        // matchup size. Where a matchup has many of something, the beat draws a cluster of small copies of
        // the unit doodle (a stylised crowd with the count labelled), not the literal count (see MatchupBeat).
        Brawler,        // a person in a fists-up fighting stance (a "man", the crowd unit for "100 men", and "you")
        Gorilla,        // a silverback gorilla (hunched shoulders, long knuckle arms, small head), grey
        GorillaKnife,   // the same gorilla, holding a little red ink knife (the modifier gag)
        Chicken,        // a plump hen (body, comb, wattle, beak, tail), the unit for "100 chickens"
        Lion,           // a lion with a full mane (the apex), warm
        HouseCat,       // a sitting house cat (full body, pointy ears, curled tail), the unit for "1000 cats"
        Toddler,        // a tiny stubby toddler (big head, little body), the unit for "100 toddlers"
        Wasp,           // a wasp (striped abdomen, wings, stinger), the unit for the swarm
        Grizzly,        // a reared grizzly bear (hump, snout, claws) as a fierce fighter, brown
        Boxer           // a professional fighter (boxing gloves, guard stance), red
    }
}
