%lang starknet

@storage_var
func pokemons(id: felt) -> (res: Pokemon) {
}

@storage_var
func pokemon_last_id() -> (id: felt) {
}

@storage_var
func user_erc20(user: felt) -> (erc20: felt) {
}

@storage_var
func likes(user: felt, pokemon_id: felt) -> (is_liked: felt) {
}

