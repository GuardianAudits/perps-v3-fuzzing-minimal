import re


def convert_to_solidity(call_sequence):
    # Regex patterns to extract the necessary parts
    call_pattern = re.compile(
        r"(?:Fuzz\.)?(\w+\([^\)]*\))(?: from: (0x[0-9a-fA-F]{40}))?(?: Gas: (\d+))?(?: Time delay: (\d+) seconds)?(?: Block delay: (\d+))?"
    )
    wait_pattern = re.compile(
        r"\*wait\*(?: Time delay: (\d+) seconds)?(?: Block delay: (\d+))?"
    )

    solidity_code = "function test_replay() public {\n"

    lines = call_sequence.strip().split("\n")
    last_index = len(lines) - 1

    for i, line in enumerate(lines):
        call_match = call_pattern.search(line)
        wait_match = wait_pattern.search(line)
        if call_match:
            call, from_addr, gas, time_delay, block_delay = call_match.groups()

            # Add prank line if from address exists
            # if from_addr:
            #     solidity_code += f'    vm.prank({from_addr});\n'

            # Add warp line if time delay exists
            if time_delay:
                solidity_code += f"    vm.warp(block.timestamp + {time_delay});\n"

            # Add roll line if block delay exists
            if block_delay:
                solidity_code += f"    vm.roll(block.number + {block_delay});\n"

            if "collateralToMarketId" in call:
                continue

            # Add function call
            if i < last_index:
                solidity_code += f"    try this.{call} {{}} catch {{}}\n"
            else:
                solidity_code += f"    {call};\n"
            solidity_code += "\n"
        elif wait_match:
            time_delay, block_delay = wait_match.groups()

            # Add warp line if time delay exists
            if time_delay:
                solidity_code += f"    vm.warp(block.timestamp + {time_delay});\n"

            # Add roll line if block delay exists
            if block_delay:
                solidity_code += f"    vm.roll(block.number + {block_delay});\n"
            solidity_code += "\n"

    solidity_code += "}\n"

    return solidity_code


# Example usage
call_sequence = """
 Fuzz.fuzz_crashWBTCPythPrice(8272663) Time delay: 3 seconds Block delay: 14246
    Fuzz.fuzz_changeOracleManagerPrice(5876995114192504108114557442559075274233847232337755884555805112560331383974,20374593907295150528490908016128133617111158061146294585622734675020521622889)
    Fuzz.fuzz_crashWBTCPythPrice(3801989)
    Fuzz.fuzz_guided_depositAndShortWBTC() Time delay: 1 seconds Block delay: 11942
    Fuzz.repayDebt() Time delay: 1 seconds Block delay: 31807
    Fuzz.fuzz_settleOrder()
    Fuzz.targetSenders() Time delay: 3 seconds Block delay: 58783
    Fuzz.fuzz_guided_depositAndShort()
    Fuzz.excludeSenders() Time delay: 3 seconds Block delay: 60
    Fuzz.collateralToMarketId(0x0) Time delay: 3 seconds Block delay: 33218
    *wait* Time delay: 10 seconds Block delay: 69950
    Fuzz.fuzz_cancelOrder(5) Time delay: 1 seconds Block delay: 35731
    *wait* Time delay: 5 seconds Block delay: 49415
    Fuzz.fuzz_cancelOrder(44) Time delay: 1 seconds Block delay: 60364
    Fuzz.pendingOrder(1256657410) Time delay: 3 seconds Block delay: 15607
    Fuzz.fuzz_guided_depositAndShort() Time delay: 1 seconds Block delay: 4223
    Fuzz.IS_TEST() Time delay: 5 seconds Block delay: 15764
    Fuzz.fuzz_modifyCollateral(8542833558636987789308118644925683403792117600965309022390609468528741291235,1676809) Time delay: 5 seconds Block delay: 27404
    Fuzz.fuzz_crashWBTCPythPrice(55) Time delay: 5 seconds Block delay: 38350
    Fuzz.fuzz_commitOrder(3153,19404086526591562380684914545785193691637301789324297873349688953609032224) Time delay: 3 seconds Block delay: 5023
    Fuzz.fuzz_crashWETHPythPrice(172660010) Time delay: 3 seconds Block delay: 60364
    Fuzz.fuzz_liquidatePosition()
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)
