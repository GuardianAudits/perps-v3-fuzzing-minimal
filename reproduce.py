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
Fuzz.fuzz_pumpWBTCPythPrice(297438859393400983384725495979791842282640572577674996747937424213431335558)
    Fuzz.fuzz_crashWETHPythPrice(76599276773013787703648646267970536833372444755365747263279817092582169507)
    Fuzz.fuzz_pumpWETHPythPrice(13474899003150616500232)
    Fuzz.fuzz_mintUSDToSynthetix(1569732514951774894792577872305511393047383155651463514057633340815359)
    Fuzz.fuzz_pumpWETHPythPrice(90698195293624529797368111175854062438945100003633099404324928445275155916980)
    Fuzz.fuzz_crashWBTCPythPrice(109384810993130552931992464493517736897175359595990643887433434869805035329189)
    Fuzz.fuzz_changeWETHPythPrice(125230)
    Fuzz.fuzz_crashWBTCPythPrice(311006992715199280756718496225144071323385641509902359095442427973106617685)
    Fuzz.fuzz_crashWETHPythPrice(85)
    Fuzz.fuzz_guided_depositAndShortWBTC()
    Fuzz.fuzz_changeWBTCPythPrice(11446343799473295649270294395403422203)
    Fuzz.fuzz_settleOrder()
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)
