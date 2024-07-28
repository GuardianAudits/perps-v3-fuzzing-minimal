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
            if from_addr:
                solidity_code += f"    vm.prank({from_addr});\n"

            # Add warp line if time delay exists
            if time_delay:
                solidity_code += f"    vm.warp(block.timestamp + {time_delay});\n"

            # Add roll line if block delay exists
            if block_delay:
                solidity_code += f"    vm.roll(block.number + {block_delay});\n"

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
 Fuzz.fuzz_changeWBTCPythPrice(4280455364831454581) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 5053
    Fuzz.fuzz_guided_createDebt_LiquidateMarginOnly(true,30954749420015391918139466440851848790163633299071895031681992968603483332913) from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 34272
    Fuzz.excludeArtifacts() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 19333
    Fuzz.fuzz_changeWBTCPythPrice(4280455364831454581) from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 24311
    Fuzz.fuzz_pumpWBTCPythPrice(4571378123040129835110645501447096099757817388479875675538670709315270443873) from: 0x0000000000000000000000000000000000010000
    Fuzz.targetArtifactSelectors() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 24987
    Fuzz.excludeSelectors() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 4223
    Fuzz.excludeSelectors() from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 1088
    Fuzz.targetArtifacts() from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_crashWBTCPythPrice(23216544756795111064671052892044071812121785505344308683573734109174097626271) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 25535
    Fuzz.targetInterfaces() from: 0x0000000000000000000000000000000000030000
    Fuzz.fuzz_pumpWBTCPythPrice(4571378123040129835110645501447096099757817388479875675538670709315270443873) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 4896
    Fuzz.targetArtifacts() from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 58783
    Fuzz.failed() from: 0x0000000000000000000000000000000000030000 Time delay: 5 seconds Block delay: 36859
    Fuzz.excludeSelectors() from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 32147
    Fuzz.fuzz_modifyCollateral(49702006450953861765807903644386942596705006307479003070109120124712674327224,1524785993) from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 46422
    Fuzz.fuzz_settleOrder() from: 0x0000000000000000000000000000000000010000 Time delay: 5 seconds Block delay: 5786
    Fuzz.fuzz_delegateCollateral(1524785993,0,86713579207806114606671108161500018359076792467074454731219611294456891961036,1524785991,1524785991) from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 30304
    Fuzz.fuzz_crashWETHPythPrice(27791911391501575981142706174694744561875260745923521918881244428685164396544) from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 5023
    Fuzz.fuzz_crashWETHPythPrice(27791911391501575981142706174694744561875260745923521918881244428685164396544) from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 50499
    Fuzz.targetArtifactSelectors() from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 11826
    Fuzz.fuzz_liquidateFlagged(26) from: 0x0000000000000000000000000000000000010000 Time delay: 2 seconds Block delay: 30256
    Fuzz.fuzz_liquidateFlagged(55) from: 0x0000000000000000000000000000000000010000 Time delay: 4 seconds Block delay: 4896
    Fuzz.fuzz_guided_createDebt_LiquidateMarginOnly(true,4370001) from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 41290
    Fuzz.targetSenders() from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 45852
    Fuzz.failed() from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 19933
    Fuzz.fuzz_changeWETHPythPrice(1524785993) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 59552
    Fuzz.fuzz_settleOrder() from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 36859
    Fuzz.pendingOrder(201468923201268763578963306507310472582) from: 0x0000000000000000000000000000000000030000 Time delay: 2 seconds Block delay: 3661
    Fuzz.IS_TEST() from: 0x0000000000000000000000000000000000020000
    Fuzz.collateralToMarketId(0xcd9a70c13c88863ece51b302a77d2eb98fbbbd65) from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 46422
    Fuzz.fuzz_liquidatePosition() from: 0x0000000000000000000000000000000000010000 Time delay: 5 seconds Block delay: 24987
    Fuzz.fuzz_guided_depositAndShort() from: 0x0000000000000000000000000000000000030000
    Fuzz.pendingOrder(527) from: 0x0000000000000000000000000000000000010000
    Fuzz.fuzz_crashWBTCPythPrice(73767554418199339812106075053837917778102426611481698007305348546559953757341) from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_pumpWETHPythPrice(513) from: 0x0000000000000000000000000000000000030000 Time delay: 6 seconds Block delay: 20349
    Fuzz.excludeContracts() from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 9920
    Fuzz.fuzz_pumpWETHPythPrice(18550952495227114971864363557780808188744923943598095365325468250271597804530) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 33357
    Fuzz.fuzz_changeOracleManagerPrice(4370001,1524785993) from: 0x0000000000000000000000000000000000010000
    Fuzz.repayDebt() from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 60364
    Fuzz.IS_TEST() from: 0x0000000000000000000000000000000000010000 Time delay: 5 seconds Block delay: 23403
    Fuzz.IS_TEST() from: 0x0000000000000000000000000000000000030000 Time delay: 6 seconds Block delay: 45852
    Fuzz.fuzz_changeWBTCPythPrice(-9223372036854775808) from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_liquidateFlaggedAccounts(253) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 561
    Fuzz.fuzz_liquidatePosition() from: 0x0000000000000000000000000000000000010000
    Fuzz.fuzz_pumpWBTCPythPrice(21443253488308386919818604701031834188266622639471657377774134086704501932199) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 35248
    Fuzz.fuzz_delegateCollateral(330924488573917606084908576629834616816,196076158967676270537707503622353966090,5963535451332192165248380555010570991972943249917332641975986078000899566176,4370000,0) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 32
    Fuzz.fuzz_liquidatePosition() from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 60267
    Fuzz.targetInterfaces() from: 0x0000000000000000000000000000000000030000 Time delay: 5 seconds Block delay: 20243
    Fuzz.fuzz_changeOracleManagerPrice(4370001,2785246858395475934513824290946353863510055321045186888325621967884044575369) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 2511
    Fuzz.fuzz_guided_createDebt_LiquidateMarginOnly(false,4370001) from: 0x0000000000000000000000000000000000030000
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)
