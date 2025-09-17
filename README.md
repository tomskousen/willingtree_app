# WillingTree App

A relationship growth app using the Want/Willing/Won't framework.

## Key Features

### Free Tier (The Game)
- Big Branch: 12 wants/needs with 25 points to distribute
- Little Branches: 3 willing items (1 random + 2 from 6 shuffled)
- 144-hour countdown timer (exactly 6 days)
- Leaves: 3 guesses worth 5 points each
- Fruit: Basic weekly scoring

### Premium Tier ($1/week)
- Deep introspection tools
- Journaling with guided prompts
- Pattern recognition & insights
- Safe discussion guides
- Growth tracking over time

## Setup Instructions

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Run: `flutter create .` in this directory
3. Replace lib/main.dart with our code
4. Run: `flutter pub get`
5. Test locally: `flutter run`

## Important Game Mechanics

- Timer starts when BOTH partners complete their Big Branch
- Points are HIDDEN when viewing partner's Big Branch for Little Branch selection
- Points are VISIBLE during guessing/scoring phase
- After scoring, players can update Big Branch and reallocate points
- 144-hour countdown (not 7 days) - "Time's Up!" triggers guessing

## Monetization
- Freemium model with $1/week premium subscription
- Premium unlocks introspection features (muddy brown/olive theme)
- Free tier is fully playable game (green theme)