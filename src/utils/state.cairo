%lang starknet

from src.utils.models import (
    Pokemon,
)

@storage_var
func pokemons(id: felt) -> (res: Pokemon) {
}

@storage_var
func pokemon_last_id() -> (id: felt) {
}

@storage_var
func likes(user: felt, pokemon_id: felt) -> (is_liked: felt) {
}

