%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.upgrades.library import Proxy
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

from src.main import initializer, upgrade

const PROXY_ADMIN = 12345;
const TOKEN_NAME = 'poktoken';
const TOKEN_SYMBOL = 'PKT';
const TOKEN_DECIMALS = 0;
const UPGRADE_HASH = 'hash';
const NAME_ONE = 'one';
const NAME_TWO = 'two';
const NAME_THREE = 'three';
const TYPE_ONE = 1;
const TYPE_TWO = 2;
const TYPE_THREE = 3;

@external
func test_initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    %{ start_prank(ids.PROXY_ADMIN) %}
    %{
        expect_events({"name": "AdminChanged", "data": [0, ids.PROXY_ADMIN]})
        expect_events({"name": "pokemon_created", "data": [ids.PROXY_ADMIN, 1, ids.NAME_ONE, ids.TYPE_ONE, 0, ids.PROXY_ADMIN]})
        expect_events({"name": "pokemon_created", "data": [ids.PROXY_ADMIN, 2, ids.NAME_TWO, ids.TYPE_TWO, 0, ids.PROXY_ADMIN]})
        expect_events({"name": "pokemon_created", "data": [ids.PROXY_ADMIN, 3, ids.NAME_THREE, ids.TYPE_THREE, 0, ids.PROXY_ADMIN]})
    %}
    initializer(
        proxy_admin=PROXY_ADMIN,
        token_name=TOKEN_NAME,
        token_symbol=TOKEN_SYMBOL,
        token_decimals=TOKEN_DECIMALS,
        name1=NAME_ONE, type1=TYPE_ONE,
        name2=NAME_TWO, type2=TYPE_TWO,
        name3=NAME_THREE, type3=TYPE_THREE,
    );
    let (saved_token_name) = name();
    assert saved_token_name = TOKEN_NAME;
    let (saved_token_symbol) = symbol();
    assert saved_token_symbol = TOKEN_SYMBOL;
    let (saved_token_decimals) = decimals();
    assert saved_token_decimals = TOKEN_DECIMALS;
    let (saved_token_supply) = totalSupply();
    assert saved_token_supply.low = 0;
    assert saved_token_supply.high = 0;

    return ();
}

@external
func test_initializer_fail_ran_twice{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ start_prank(ids.PROXY_ADMIN) %}
    initializer(
        proxy_admin=PROXY_ADMIN,
        token_name=TOKEN_NAME,
        token_symbol=TOKEN_SYMBOL,
        token_decimals=TOKEN_DECIMALS,
        name1=NAME_ONE, type1=TYPE_ONE,
        name2=NAME_TWO, type2=TYPE_TWO,
        name3=NAME_THREE, type3=TYPE_THREE,
    );
    %{ expect_revert(error_message="Proxy: contract already initialized") %}
    initializer(
        proxy_admin=PROXY_ADMIN,
        token_name=TOKEN_NAME,
        token_symbol=TOKEN_SYMBOL,
        token_decimals=TOKEN_DECIMALS,
        name1=NAME_ONE, type1=TYPE_ONE,
        name2=NAME_TWO, type2=TYPE_TWO,
        name3=NAME_THREE, type3=TYPE_THREE,
    );
    return ();
}

@external
func test_upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ start_prank(ids.PROXY_ADMIN) %}
    initializer(
        proxy_admin=PROXY_ADMIN,
        token_name=TOKEN_NAME,
        token_symbol=TOKEN_SYMBOL,
        token_decimals=TOKEN_DECIMALS,
        name1=NAME_ONE, type1=TYPE_ONE,
        name2=NAME_TWO, type2=TYPE_TWO,
        name3=NAME_THREE, type3=TYPE_THREE,
    );

    upgrade(UPGRADE_HASH);

    let (new_implementation_hash) = Proxy.get_implementation_hash();
    assert new_implementation_hash = UPGRADE_HASH;

    return ();
}

@external
func test_upgrade_fail_not_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    %{ stop_prank_callable = start_prank(ids.PROXY_ADMIN) %}
    initializer(
        proxy_admin=PROXY_ADMIN,
        token_name=TOKEN_NAME,
        token_symbol=TOKEN_SYMBOL,
        token_decimals=TOKEN_DECIMALS,
        name1=NAME_ONE, type1=TYPE_ONE,
        name2=NAME_TWO, type2=TYPE_TWO,
        name3=NAME_THREE, type3=TYPE_THREE,
    );
    %{ stop_prank_callable() %}
    %{ expect_revert(error_message="Proxy: caller is not admin") %}

    upgrade(UPGRADE_HASH);

    return ();
}