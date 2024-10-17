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
Fuzz.fuzz_mintUSDToSynthetix(389710261765692191029748882101845950071414929515871786935606764914907558)
    Fuzz.fuzz_pumpWETHPythPrice(213082464454704143435197186790335736291542479520687203683051485983701763210) Time delay: 1 seconds Block delay: 1663
    Fuzz.fuzz_pumpWETHPythPrice(606084226024809351428367687748612859596009861826803420244472732797531619777)
    Fuzz.fuzz_pumpWBTCPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639934)
    Fuzz.fuzz_crashWETHPythPrice(431709439691528361455798752391340009837311401210745473296154915217026177544)
    Fuzz.fuzz_pumpWETHPythPrice(4060922002706325220599678633686257164675650391452921803847003219840808937090)
    Fuzz.fuzz_pumpWETHPythPrice(1758362263769669530757153781318605093134542995492870982874558406809260073431)
    Fuzz.fuzz_changeWBTCPythPrice(102796653981161089979539327737888481704)
    Fuzz.fuzz_guided_depositAndShortWBTC()
    Fuzz.fuzz_pumpWBTCPythPrice(20986833545337926496483639114214100638069420920141707445495424223586535142999)
    Fuzz.fuzz_crashWETHPythPrice(572566638634433125154357921980847482949647729221151692155982121329987606)
    Fuzz.fuzz_settleOrder()
    Fuzz.fuzz_crashWETHPythPrice(468788714) Time delay: 3 seconds Block delay: 4032
    Fuzz.fuzz_guided_createDebt_LiquidateMarginOnly(false,829006349567248821756895048805294982598048294665499834673585248951155102272)
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)
