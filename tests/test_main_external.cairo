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

// `example` is bugged, issue: https://github.com/software-mansion/protostar/issues/1577
// additionally, it does not work without specyfing the parameter name explicitly
// I don't know whether those issues are related to each other, will check after first one is fixed
@external
func setup_create_valid_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    reward_user(USER);
    %{
        # example(pokemon_type=1)
        # example(pokemon_type=2)
        # example(pokemon_type=3)
        given(pokemon_type = strategy.integers(1, 3),)
    %}
    return ();
}

@external
func test_create_valid_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pokemon_type: felt
) {
    alloc_locals;
    let pokemon_name = 'asdf';
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let (user_id) = get_caller_address();
    let (balance_before) = balanceOf(user_id);

    %{ expect_events({"name": "pokemon_created", "data": [ids.user_id, 1, ids.pokemon_name, ids.pokemon_type, 0, ids.user_id]}) %}
    create_pokemon(pokemon_name, pokemon_type);
    
    let (pokemon_id) = pokemon_last_id.read();
    assert pokemon_id = 1;
    
    let (created_pokemon) = pokemons.read(id=pokemon_id);
    assert created_pokemon.id = 1;
    assert created_pokemon.name = pokemon_name;
    assert created_pokemon.type = pokemon_type;
    assert created_pokemon.likes = 0;
    assert created_pokemon.owner = user_id;

    let (balance_after) = balanceOf(user_id);
    assert balance_before.low - 1 = balance_after.low;
    assert balance_before.high = balance_after.high;

    %{ stop_prank_callable() %}
    return ();
}

@external
func setup_add_pokemon_invalid_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{
        # example(pokemon_type=4)
        given(pokemon_type = strategy.integers(4, 6))
    %}
    return ();
}

@external
func test_add_pokemon_invalid_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pokemon_type: felt
) {
    alloc_locals;
    let pokemon_name = 123;
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let (user_id) = get_caller_address();
    
    %{ expect_revert(error_message = "You cannot create a pokemon of type {type}, allowed types: fire, water, grass".format(type = ids.pokemon_type)) %}
    create_pokemon(pokemon_name, pokemon_type);
    
    %{ stop_prank_callable() %}
    return ();
}

@external
func setup_add_pokemon_duplicate_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    reward_user(USER);
    return ();
}

@external
func test_add_pokemon_duplicate_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let pokemon_name = 123;
    let pokemon_type = 2;
    %{ stop_prank_callable = start_prank(ids.USER) %}
    create_pokemon(pokemon_name, pokemon_type);

    %{ expect_revert(error_message = "Pokemon named {name} already exists".format(name = ids.pokemon_name)) %}
    create_pokemon(pokemon_name, pokemon_type);

    %{ stop_prank_callable() %}
    return ();

}   

@external
func test_add_pokemon_no_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    %{ stop_prank_callable = start_prank(ids.USER) %}
    %{ expect_revert(error_message = "ERC20: burn amount exceeds balance") %}
    create_pokemon(111, 1);

    %{ stop_prank_callable() %}
    return ();
}

@external
func setup_like_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    reward_user(USER);
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let pokemon_name = 123;
    let pokemon_type = 1;
    create_pokemon(pokemon_name, pokemon_type);
    %{ stop_prank_callable() %}
    %{ 
        # example(pokemon_name = ids.pokemon_name)
        given(pokemon_name = strategy.integers(ids.pokemon_name, ids.pokemon_name))
    %}
    return ();
}

@external
func test_like_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pokemon_name: felt
) {
    alloc_locals;
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let (user_id) = get_caller_address();
    let (pokemon_id) = pokemon_last_id.read();
    let (balance_before) = balanceOf(user_id);    
    assert balance_before.low = 0;
    assert balance_before.high = 0;

    let (pokemon) = pokemons.read(pokemon_id);
    %{ expect_events({"name": "pokemon_liked", "data": [ids.user_id, ids.pokemon.id, ids.pokemon.name, ids.pokemon.type, ids.pokemon.likes, ids.user_id, ids.pokemon.likes + 1]}) %}
    like_pokemon(pokemon_name);

    let (pokemon_updated) = pokemons.read(pokemon_id);
    assert pokemon_updated.likes = pokemon.likes + 1;

    let (balance_after) = balanceOf(user_id);
    assert balance_after.low = balance_before.low + 1;
    assert balance_after.high = balance_before.high;

    %{ stop_prank_callable() %}
    return ();
}

@external
func setup_like_pokemon_twice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    reward_user(USER);
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let pokemon_name = 123;
    let pokemon_type = 1;
    create_pokemon(pokemon_name, pokemon_type);
    %{ stop_prank_callable() %}
    %{ 
        # example(pokemon_name = ids.pokemon_name)
        given(pokemon_name = strategy.integers(ids.pokemon_name, ids.pokemon_name))
    %}
    return ();
}

@external
func test_like_pokemon_twice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pokemon_name: felt
) {
    alloc_locals;
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let (user_id) = get_caller_address();
    let (pokemon_id) = pokemon_last_id.read();
    let (pokemon) = pokemons.read(pokemon_id);
    like_pokemon(pokemon_name);
    
    %{ expect_revert(error_message = "You have already liked that pokemon") %}
    like_pokemon(pokemon_name);

    %{ stop_prank_callable() %}
    return ();
}