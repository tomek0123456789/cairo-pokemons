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

@external
func setup_show_pokemon_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    reward_user(USER);
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let pokemon_name = 123;
    let pokemon_type = 1;
    create_pokemon(name=pokemon_name, type=pokemon_type);
    %{
        given(name = strategy.integers(ids.pokemon_name, ids.pokemon_name), type = strategy.integers(ids.pokemon_type, ids.pokemon_type), user_id = strategy.integers(ids.USER, ids.USER))
    %}
    return ();
}

@external
func test_show_pokemon_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, type: felt, user_id: felt
) {
    let (pokemon) = show_pokemon(name);
    assert pokemon.id = 1;
    assert pokemon.name = name;
    assert pokemon.type = type;
    assert pokemon.likes = 0;
    assert pokemon.owner = user_id; 
    return ();
}

@external
func setup_show_pokemon_invalid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ given(invalid_name = strategy.integers(0, 0)) %}
    return ();
}

@external
func test_show_pokemon_invalid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    invalid_name: felt
) {
    %{ expect_revert(error_message = "Invalid pokemon name") %}
    let (pokemon) = show_pokemon(invalid_name);

    return ();
}

@external
func setup_show_pokemon_nonexisting{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ 
        given(invalid_name = strategy.integers(1, 3)) 
    %}
    return ();
}

@external
func test_show_pokemon_nonexisting{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    invalid_name: felt
) {
    %{ expect_revert(error_message = "Pokemon named {name} does not exist".format(name = ids.invalid_name)) %}
    let (pokemon) = show_pokemon(invalid_name);
    return ();
}

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

@external
func setup_show_all_pokemons_many{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    reward_user(USER);
    reward_user(USER);
    reward_user(USER);
    %{ stop_prank_callable = start_prank(ids.USER) %}
    let name = 1;
    let type = 1;
    create_pokemon(name, type);
    create_pokemon(name + 1, type + 1);
    create_pokemon(name + 2, type + 2);
    %{
        # example(begin_id = 1, begin_name = ids.name, begin_type = ids.type, likes = 0, owner = ids.USER) 
        given(begin_id = strategy.integers(1, 1), begin_name = strategy.integers(ids.name, ids.name), begin_type = strategy.integers(ids.type, ids.type), likes = strategy.integers(0, 0), owner = strategy.integers(ids.USER, ids.USER)) 
        stop_prank_callable()
    %}
    return ();
}

@external
func test_show_all_pokemons_many{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    begin_id: felt, begin_name: felt, begin_type: felt, likes: felt, owner: felt
) {
    alloc_locals;
    let (pokemons_len, pokemons) = show_all_pokemons();
    assert pokemons_len = 3;
    // let first = pokemons;
    // let second = pokemons + Pokemon.SIZE; 
    // let third = pokemons + 2 * Pokemon.SIZE;
    let first = pokemons[0];
    let second = pokemons[1];
    let third = pokemons[2];

    assert first.id = 3;
    assert first.name = 3;
    assert first.type = 3;
    assert first.likes = 0;
    assert first.owner = owner;

    assert second.id = 2;
    assert second.name = 2;
    assert second.type = 2;
    assert second.likes = 0;
    assert second.owner = owner;

    assert third.id = 1;
    assert third.name = 1;
    assert third.type = 1;
    assert third.likes = 0;
    assert third.owner = owner;
    return ();
}

@external
func setup_show_user_pokemons{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    const SECOND_USER = 3456;
    const THIRD_USER = 7890;
    %{ stop_prank_callable = start_prank(ids.USER) %}
    reward_user(USER);
    create_pokemon(name=1, type=1);
    %{ stop_prank_callable() %}
    %{ stop_prank_callable = start_prank(ids.SECOND_USER) %}
    reward_user(SECOND_USER);
    reward_user(SECOND_USER);
    create_pokemon(name=2, type=2);
    create_pokemon(name=3, type=3);
    %{ stop_prank_callable() %}
    // %{ stop_prank_callable = start_prank(ids.THIRD_USER) %}
    // reward_user(THIRD_USER);
    // reward_user(THIRD_USER);
    // reward_user(THIRD_USER);
    // create_pokemon(name=4, type=1);
    // create_pokemon(name=5, type=2);
    // create_pokemon(name=6, type=3);
    // %{ stop_prank_callable() %}

    // let first_one = pokemons.read(id=1);
    // let second_one = pokemons.read(id=2);
    // let second_two = pokemons.read(id=3);
    // let third_one = pokemons.read(id=4);
    // let third_two = pokemons.read(id=5);
    // let third_three = pokemons.read(id=6);
    // tempvar first: Pokemon* = cast((first_one), Pokemon*);
    // tempvar second: Pokemon* = cast((second_one, second_two), Pokemon*);
    // tempvar third: Pokemon* = cast((third_one, third_two, third_three), Pokemon*);
    %{
        given(first_len = strategy.integers(1, 1), second_len = strategy.integers(2, 2), third_len = strategy.integers(0, 0),
            first_user_id = strategy.integers(ids.USER, ids.USER), second_user_id = strategy.integers(ids.SECOND_USER, ids.SECOND_USER), third_user_id = strategy.integers(ids.THIRD_USER, ids.THIRD_USER))
    %}
    return ();   
}

@external
func test_show_user_pokemons{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    first_len: felt, second_len: felt, third_len: felt, first_user_id: felt, second_user_id: felt, third_user_id: felt
) {
    let (pokemons_first_len, pokemons_first) = show_user_pokemons(first_user_id);
    assert pokemons_first_len = first_len;
    assert pokemons_first[0].owner = first_user_id;
    
    let (pokemons_second_len, pokemons_second) = show_user_pokemons(second_user_id);
    assert pokemons_second_len = second_len;
    assert pokemons_second[0].owner = second_user_id;
    assert pokemons_second[1].owner = second_user_id;

    let (pokemons_third_len, pokemons_third) = show_user_pokemons(third_user_id);
    assert pokemons_third_len = third_len;

    return ();
}

@external
func test_show_user_pokemons_invalid_user{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    const INVALID_ID = 0;
    %{ expect_revert(error_message = "Invalid user") %}
    let (pokemons_len, pokemons) = show_user_pokemons(INVALID_ID);
    %{ stop_prank_callable() %}

    return ();
}