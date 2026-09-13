
// Returns a color for the specified Deck index
function colorForDeck(deckIdx)
{
    switch (deckIdx)
    {
      case 1:
        return Color.Mint;
      case 2:
        return Color.Cyan;

      case 3:
        return Color.Plum
      case 4:
        return Color.Fuchsia;
    }

    // Fall-through...
    return Color.Black;
}

// primary decks defualt to track, secondary decks default to remix
function defaultTypeForDeck(deckIdx)
{
    return (deckIdx > 2) ? DeckType.Remix : DeckType.Track
}

function deckTypeSupportsGridAdjust(deckType)
{
    return deckType == DeckType.Track || deckType == DeckType.Stem;
}

function linkedDeckIdx(deckIdx)
{
    switch (deckIdx)
    {
    // Deck A and C are linked
    case 0: return 2;
    case 2: return 0;
    // Deck B and D are linked
    case 1: return 3;
    case 3: return 1;
    }
}
