%lang starknet

@event
func pokemon_created(
    user: felt, pokemon: Pokemon
) {
}

@event
func pokemon_liked(
    user: felt, pokemon: Pokemon, likes: felt
) {
}
