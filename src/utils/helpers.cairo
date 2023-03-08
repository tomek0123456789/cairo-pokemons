%lang starknet 

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le_felt,
    assert_not_equal,
    unsigned_div_rem,
    split_felt,
)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

from src.utils.models import (
    Pokemon,
)

from src.utils.state import (
    pokemons,
    pokemon_last_id,
    likes,
)

from src.utils.events import (
    pokemon_created,
    pokemon_liked,
)
from openzeppelin.token.erc20.library import ERC20

from openzeppelin.token.erc20.presets.ERC20 import (
    name,
    symbol,
    totalSupply,
    decimals,
    balanceOf,
    allowance,
    transfer,
    transferFrom,
    approve,
    increaseAllowance,
    decreaseAllowance
)
func get_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, id: felt
) -> (pokemon: Pokemon) {
    let (pokemon) = pokemons.read(id);
    if (id == 0) {
        return (pokemon=pokemon);
    }
    if (pokemon.name == name) {
        return (pokemon=pokemon);
    } else {
        return get_pokemon(name=name, id=id - 1);
    }
}

func get_all_pokemons{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arr_len: felt, arr: Pokemon*, index: felt
) -> (pokemons_len: felt, pokemons: Pokemon*) {
    if (index == 0) {
        return (pokemons_len=arr_len, pokemons=arr);
    }
    let (pokemon) = pokemons.read(id=index);
    assert arr[arr_len] = pokemon;
    return get_all_pokemons(arr_len=arr_len + 1, arr=arr, index=index - 1);
}

func get_user_pokemons{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arr_len: felt, arr: Pokemon*, index: felt, user_id: felt
) -> (pokemons_len: felt, pokemons: Pokemon*) {
    if (index == 0) {
        return (pokemons_len=arr_len, pokemons=arr);
    }
    let (pokemon) = pokemons.read(id=index);
    if (pokemon.owner == user_id) {
        assert arr[arr_len] = pokemon;
        return get_user_pokemons(arr_len=arr_len + 1, arr=arr, index=index - 1, user_id=user_id);
    } else {
        return get_user_pokemons(arr_len=arr_len, arr=arr, index=index - 1, user_id=user_id);
    }
}

// TODO string length check
func _create_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, type: felt, user: felt
) -> () {
    alloc_locals;
    let (last_id) = pokemon_last_id.read();
    let (pokemon) = get_pokemon(name=name, id=last_id);
    with_attr error_message("Pokemon named {name} already exists") {
        assert_not_equal(name, pokemon.name);
    }
    //assuming that types are: fire - 1, water - 2, grass - 3
    with_attr error_message("You cannot create a pokemon of type {type}, allowed types: fire, water, grass") {
        assert (type - 1) * (type - 2) * (type - 3) = 0;
    } 
    tempvar new_pokemon = Pokemon(id=last_id + 1, name=name, type=type, likes=0, owner=user);
    pokemon_last_id.write(last_id + 1);
    pokemons.write(last_id + 1, new_pokemon);
    pokemon_created.emit(user=user, pokemon=new_pokemon);
    return ();
}

func pay{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt, credit_requirement: felt
) {
    ERC20._burn(user, Uint256(credit_requirement, 0));
    return ();
}

func reward_user{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(user: felt) {
    ERC20._mint(user, Uint256(1, 0));
    return ();
}

func ensure_user{syscall_ptr: felt*}() -> (caller: felt) {
    let (caller) = get_caller_address();
    with_attr error_message("User not authenticated") {
        assert_not_zero(caller);
    }
    return (caller,);
}

