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

const USER = 123123123;
const OTHER_USER = 7890;

// it somehow doesn't work with `example`
@external
func setup_create_valid_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    reward_user(USER);
    reward_user(USER);
    reward_user(USER);
    %{
        example(pokemon_type=1)
        example(pokemon_type=2)
        example(pokemon_type=3)
    %}
    return ();
}

@external
func test_create_valid_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pokemon_type: felt
) {
    // alloc_locals;

    assert 1 = 2;
    let pokemon_name = 1234;
    assert 1 = 2;
    %{ stop_prank_callable = start_prank(ids.USER) %}
    assert 1 = 2;
    let (user_id) = get_caller_address();
    assert 1 = 2;
    let (balance_before) = balanceOf(user_id);

    assert 1 = 2;

    assert 1 = 2;
    %{ expect_events({"name": "pokemon_created", "data": [ids.user_id, 1, ids.pokemon_name, ids.pokemon_type, 0, ids.user_id]}) %}
    assert 1 = 2;
    create_pokemon(po kemon_name, pokemon_type);
    
    assert 1 = 2;
    let (pokemon_id) = pokemon_last_id.read();
    assert 1 = 2;
    assert pokemon_id = 1;
    
    assert 1 = 2;
    let (created_pokemon) = pokemons.read(id=pokemon_id);
    assert 1 = 2;
    assert created_pokemon.id = 1;
    assert 1 = 2;
    assert created_pokemon.name = pokemon_name;
    assert 1 = 2;
    assert created_pokemon.type = pokemon_type;
    assert 1 = 2;
    assert created_pokemon.likes = 0;
    assert 1 = 2;
    assert created_pokemon.owner = user_id;
    assert 1 = 2;

    assert 1 = 2;
    let (balance_after) = balanceOf(user_id);
    assert balance_before.low - 1 = balance_after.low;
    assert balance_before.high = balance_after.high;

    %{ stop_prank_callable() %}
    return ();
}

@external
func test_create_valid_pokemonn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    reward_user(USER);
    reward_user(USER);
    reward_user(USER);
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let pokemon_name = 1234;
    let pokemon_type = 1;
    let (user_id) = get_caller_address();
    let (balance_before) = balanceOf(user_id);

    %{ expect_events({"name": "pokemon_created", "data": [ids.user_id, 1, ids.pokemon_name, ids.pokemon_type, 0, ids.user_id]}) %}
    create_pokemon(pokemon_name, pokemon_type);
    %{ expect_events({"name": "pokemon_created", "data": [ids.user_id, 2, ids.pokemon_name + 1, ids.pokemon_type + 1, 0, ids.user_id]}) %}
    create_pokemon(pokemon_name + 1, pokemon_type + 1);
    %{ expect_events({"name": "pokemon_created", "data": [ids.user_id, 3, ids.pokemon_name + 2, ids.pokemon_type + 2, 0, ids.user_id]}) %}
    create_pokemon(pokemon_name + 2, pokemon_type + 2);

    let (pokemon_id) = pokemon_last_id.read();
    let (created_pokemon) = pokemons.read(id=pokemon_id);

    assert pokemon_id = 3;
    assert created_pokemon.id = 3;
    assert created_pokemon.name = pokemon_name + 2;
    assert created_pokemon.type = pokemon_type + 2;
    assert created_pokemon.likes = 0;
    assert created_pokemon.owner = user_id;

    let (balance_after) = balanceOf(user_id);
    
    assert balance_before.low - 3 = balance_after.low;
    assert balance_before.high = balance_after.high;

    %{ stop_prank_callable() %}
    return ();
}

// @external
// func setup_add_pokemon_invalid_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     reward_user(USER);
//     reward_user(USER);
//     reward_user(USER);
//     %{
//         example(pokemon_type=4)
//     %}
//     return ();
// }

// @external
// func test_add_pokemon_invalid_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     pokemon_type: felt
// ) {
//     alloc_locals;
//     let pokemon_name = 123;
//     %{ stop_prank_callable = start_prank(ids.USER) %}
//     let (user_id) = get_caller_address();
    
//     %{ expect_revert("You cannot create a pokemon of type {type}, allowed types: fire, water, grass.".format(type = ids.pokemon_type)) %}
//     create_pokemon(pokemon_name, pokemon_type);
    
//     %{ stop_prank_callable() %}
//     return ();
// }

// @external
// func setup_add_pokemon_duplicate_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     reward_user(USER);
//     reward_user(USER);
//     reward_user(USER);
// //    let pokemon_name = 123;
//     %{
//         example(pokemon_name=123)
//     %} 
//    return ();
// }

// @external
// func test_add_pokemon_duplicate_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     pokemon_name: felt
// ) {
//     alloc_locals;
//     let type_one = 1;
//     let type_two = 2;
//     %{ stop_prank_callable = start_prank(ids.USER) %}
//     let (user_id) = get_caller_address();
//     create_pokemon(pokemon_name, type_one);

//     %{ expect_revert("Pokemon of name {name} already exists.".format(name = ids.pokemon_name)) %}
//     create_pokemon(pokemon_name, type_one);

//     %{ expect_revert("Pokemon of name {name} already exists.".format(name = ids.pokemon_name)) %}
//     create_pokemon(pokemon_name, type_two);

//     %{ stop_prank_callable() %}
//     return ();

// }   

// @external
// func setup_like_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     reward_user(USER);
//     %{ stop_prank_callable = start_prank(ids.USER) %}
//     let pokemon_name = 123;
//     let pokemon_type = 1;
//     create_pokemon(pokemon_name, pokemon_type);
//     %{ stop_prank_callable() %}
//     return ();
// }

// @external
// func test_like_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let pokemon_name = 123;
//     let pokemon_id = 1;
//     let pokemon_type = 1;
//     %{ stop_prank_callable = start_prank(ids.USER) %}
//     let (user_id) = get_caller_address();
//     let (balance_before) = balanceOf(user_id);

//     assert balance_before.low = 0;
//     assert balance_before.high = 0;

//     let (pokemon) = pokemons.read(pokemon_id);
    
//     %{ expect_events({"name": "pokemon_liked", "data": [ids.user_id, ids.pokemon.id, ids.pokemon.name, ids.pokemon.type, ids.pokemon.likes, ids.user_id, ids.pokemon.likes + 1]}) %}
//     like_pokemon(pokemon_name);

//     let (pokemon_updated) = pokemons.read(pokemon_id);
    
//     assert pokemon_updated.likes = pokemon.likes + 1;

//     let (balance_after) = balanceOf(user_id);
    
//     assert balance_after.low = balance_before.low + 1;
//     assert balance_after.high = balance_before.high;

//     %{ stop_prank_callable() %}
//     return ();
// }
