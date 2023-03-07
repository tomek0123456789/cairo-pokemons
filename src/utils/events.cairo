%lang starknet

from src.utils.models import (
    Pokemon,
)

@event
func pokemon_created(
    user: felt, pokemon: Pokemon
) {
}

@event
func pokemon_liked(
    user: felt, pokemon: Pokemon, updated_likes: felt
) {
}
