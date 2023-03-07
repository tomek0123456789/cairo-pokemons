%lang starknet

from starkware.starknet.common.syscalls import (
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le_felt,
    assert_not_equal,
    unsigned_div_rem,
    split_felt,
    assert_nn,
)

from src.utils.helpers import ( 
    get_pokemon,
    get_all_pokemons,
    get_user_pokemons,
    _create_pokemon,
    pay,
    reward_user,
    ensure_user,
)

from src.utils.events import (
    pokemon_created,
    pokemon_liked,
)

from src.utils.models import (
    Pokemon,
)

from src.utils.state import (
    pokemons,
    pokemon_last_id,
    likes,
)

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc20.library import ERC20

///////////////////////////////external

@external
func like_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt
) {
    alloc_locals;
    let (user) = ensure_user();
    let (last_id) = pokemon_last_id.read();
    let (pokemon) = get_pokemon(name=name, id=last_id);
    with_attr error_message("Pokemon named {name} does not exist.") {
        assert_not_zero(pokemon.id);
    }
    let (is_liked) = likes.read(user=user, pokemon_id=pokemon.id);
    with_attr error_message("You have already liked that pokemon.") {
        assert_not_equal(is_liked, 1);
    }
    likes.write(user=user, pokemon_id=pokemon.id, value=1);
    pokemons.write(id=pokemon.id, value=Pokemon(id=pokemon.id, name=pokemon.name, type=pokemon.type, likes=pokemon.likes + 1, owner=pokemon.owner));
    pokemon_liked.emit(user=user, pokemon=pokemon, updated_likes=pokemon.likes + 1);
    reward_user(user=user);
    return ();
}

@external
func create_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, type: felt
) {
    alloc_locals;
    let (user) = ensure_user();
    _create_pokemon(name=name, type=type, user=user);
    pay(user=user, credit_requirement=1);
    return ();
}
///////////////////////////////upgrade & init

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt, token_name: felt, token_symbol: felt, token_decimals: felt, name1: felt, type1: felt, name2: felt, type2: felt, name3: felt, type3: felt
) {
    alloc_locals;
    ERC20.initializer(token_name, token_symbol, token_decimals);
    Proxy.initializer(proxy_admin);
    _create_pokemon(name=name1, type=type1, user=proxy_admin);
    _create_pokemon(name=name2, type=type2, user=proxy_admin);
    _create_pokemon(name=name3, type=type3, user=proxy_admin);
    return ();
}

///////////////////////////////views

@view
func show_all_pokemons{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (pokemons_len: felt, pokemons: Pokemon*) {
    let (pokemons: Pokemon*) = alloc();
    let (last_id) = pokemon_last_id.read();
    let (pokemons_len, pokemons) = get_all_pokemons(arr_len=0, arr=pokemons, index=last_id);
    return (pokemons_len=pokemons_len, pokemons=pokemons);
}

@view
func show_pokemon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt
) -> (pokemon: Pokemon) {
    let (last_id) = pokemon_last_id.read();
    let (pokemon) = get_pokemon(name=name, id=last_id);
    with_attr error_message("Pokemon named {name} does not exist.") {
        assert_not_zero(pokemon.id);
    }
    return (pokemon=pokemon);
}

@view
func show_user_pokemons{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user_id: felt
) -> (pokemons_len: felt, pokemons: Pokemon*) {
    let (last_id) = pokemon_last_id.read();
    let (empty_pokemon_arr: Pokemon*) = alloc();
    let (pokemons_len, pokemons) = get_user_pokemons(arr_len=0, arr=empty_pokemon_arr, index=last_id, user_id=user_id);
    return (pokemons_len=pokemons_len, pokemons=pokemons);
}