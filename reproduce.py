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
Fuzz.targetArtifactSelectors()
Fuzz.fuzz_mintUSDToSynthetix(77609116061247720439301554353117805030910174819943417500208990074415498039756)
*wait* Time delay: 1 seconds Block delay: 24987
Fuzz.fuzz_modifyCollateral(846479,42455110974216229615166798737531933178411162999211475029814481343651673542840)
Fuzz.fuzz_changeWBTCPythPrice(110162207160741183414151297851270448845)
Fuzz.excludeContracts()
Fuzz.fuzz_commitOrder(135599092879623243520123544605865711069,1524785992)
Fuzz.excludeSenders()
Fuzz.fuzz_changeOracleManagerPrice(37426014340995115448623149420681133265864066699369593744321910871928906413409,29542189701434751843799066396196757251664367850689765218183527863352899633410)
Fuzz.fuzz_changeWETHPythPrice(2316986167)
Fuzz.fuzz_changeOracleManagerPrice(115501968635480222204459835154239901506369535519422016282831558451322023560752,4369999) Time delay: 3 seconds Block delay: 23978
Fuzz.fuzz_guided_depositAndShortWBTC()
Fuzz.fuzz_payDebt(200242343394096332541676665486758798950)
Fuzz.fuzz_pumpWETHPythPrice(79291439750381281044643028572800723581790930887782017714671751446694421164376)
Fuzz.fuzz_settleOrder()
Fuzz.targetArtifactSelectors()
Fuzz.fuzz_modifyCollateral(44693265316351470267345528251035516808706335773470830302348216559009956862813,20512456656501161345335800194779957184607338153999306528389159339149033259416)
Fuzz.fuzz_modifyCollateral(1240119390,37183721945489340350801955465707208093421979588102115173420442284)
Fuzz.fuzz_commitOrder(358,4370000)
Fuzz.fuzz_crashWBTCPythPrice(76053657604320089974150782730152095460531521811242977150749962349289394142393)
Fuzz.excludeContracts() Time delay: 1 seconds Block delay: 3621
Fuzz.excludeSenders() Time delay: 1 seconds Block delay: 42595
Fuzz.fuzz_changeWBTCPythPrice(85531549762756941508645855209982258642)
Fuzz.fuzz_settleOrder()
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)
