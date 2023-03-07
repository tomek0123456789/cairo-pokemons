%lang starknet
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

from src.main import (
    create_pokemon,
    like_pokemon,
    show_all_pokemons,
    show_pokemon,
    show_user_pokemons,
)
from src.utils.helpers import (
    reward_user, 
    balanceOf,
)
from src.utils.models import Pokemon

from src.utils.state import (
    pokemons,
    pokemon_last_id,
    likes,
)

const USER = 2137;
const OTHER_USER = 7890;

@external
func test_show_all_pokemons_empty{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (pokemons_len, pokemons) = show_all_pokemons();
    assert pokemons_len = 0;
    return ();
}

@external
func setup_show_all_pokemons_one{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    reward_user(USER);
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let name = 123;
    let type = 2;
    create_pokemon(name, type);
    %{
        example(id = 1, name = ids.name, type = ids.type, likes = 0, owner = ids.USER) 
    %}
    return ();
}

@external
func test_show_all_pokemons_one{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: felt, name: felt, type: felt, likes: felt, owner: felt
) {
    alloc_locals;
    let (pokemons_len, pokemons) = show_all_pokemons();
    assert pokemons_len = 1;
    let first_pokemon = pokemons; 
    assert first_pokemon.id = id;   //pokemons.id works as well
    assert first_pokemon.name = name;
    assert first_pokemon.type = type;
    assert first_pokemon.likes = likes + 1;
    assert first_pokemon.owner = owner;
    return ();
}

// @external
// func test_show_pokemon_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     arguments
// ) {
    
// }