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
 Fuzz.fuzz_pumpWBTCPythPrice(87533894305706623835127403366182214841640945574257531966164707911797135609362) from: 0x0000000000000000000000000000000000030000
    Fuzz.failed() from: 0x0000000000000000000000000000000000030000
    Fuzz.excludeSelectors() from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 23653
    Fuzz.pendingOrder(198157980115751335463707764415661308873) from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 800
    Fuzz.fuzz_modifyCollateral(24092337307607371349201338000150018698563060124685791176197706600483751518467,90407037280924408380053388513981287048452607374058181965830948600213731242434) from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 54450
    Fuzz.failed() from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 15367
    Fuzz.zeroOutMemory() from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 15367
    Fuzz.fuzz_modifyCollateral(30254981041208237121442751022686994243506136113484675422420858878955062105627,1524785991) from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_guided_depositAndShortWBTC() from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 30042
    Fuzz.fuzz_changeWETHPythPrice(3371411820699086044) from: 0x0000000000000000000000000000000000020000
    Fuzz.repayDebt() from: 0x0000000000000000000000000000000000020000
    Fuzz.excludeSelectors() from: 0x0000000000000000000000000000000000010000
    Fuzz.targetSelectors() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 30256
    Fuzz.fuzz_mintUSDToSynthetix(58319597077716673645932964154407652621469602560859317685919569768048102057668) from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_settleOrder() from: 0x0000000000000000000000000000000000020000 Time delay: 5 seconds Block delay: 23403
    Fuzz.fuzz_pumpWBTCPythPrice(82817779763846017808909410027613035085688643318141728797755601145978533293377) from: 0x0000000000000000000000000000000000010000 Time delay: 5 seconds Block delay: 53678
    Fuzz.targetArtifactSelectors() from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 4462
    Fuzz.fuzz_pumpWBTCPythPrice(19488746330700717173729999299626481610075830215268097516715688792938728795577) from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 23275
    Fuzz.excludeSenders() from: 0x0000000000000000000000000000000000010000 Time delay: 5 seconds Block delay: 561
    Fuzz.fuzz_mintUSDToSynthetix(4370000) from: 0x0000000000000000000000000000000000030000
    Fuzz.fuzz_liquidatePosition() from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 30256
    Fuzz.fuzz_payDebt(194164902771823277421466735235281904579) from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 54809
    Fuzz.fuzz_pumpWETHPythPrice(18049749202201179818722872742054829732607359957881867016432298076426715384390) from: 0x0000000000000000000000000000000000020000
    Fuzz.targetInterfaces() from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 60055
    Fuzz.fuzz_crashWETHPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639934) from: 0x0000000000000000000000000000000000030000
    Fuzz.fuzz_changeOracleManagerPrice(23400675182106258488606864710744411171724282909129838509255408941851036610387,4370000) from: 0x0000000000000000000000000000000000020000 Time delay: 4 seconds Block delay: 8447
    Fuzz.fuzz_guided_createDebt_LiquidateMarginOnly(false,10448546154597721895128468398821108859332993338374862366538266264915089241453) from: 0x0000000000000000000000000000000000010000
    Fuzz.fuzz_crashWBTCPythPrice(2459009544832) from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 36859
    Fuzz.fuzz_delegateCollateral(135316917356334091652617671628503220893,256186319903586881582888722810996732870,4369999,115792089237316195423570985008687907853269984665640564039457584007913129639935,82249183903970785728399494859185397493376003927400094584376132305559208207554) from: 0x0000000000000000000000000000000000020000 Time delay: 5 seconds Block delay: 59982
    Fuzz.fuzz_crashWETHPythPrice(1524785993) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 58783
    Fuzz.collateralToMarketId(0x1f79a7d7fe04baf6b5343131cd71c52a749cc6f4) from: 0x0000000000000000000000000000000000030000 Time delay: 4 seconds Block delay: 3661
    Fuzz.excludeSelectors() from: 0x0000000000000000000000000000000000010000 Time delay: 5 seconds Block delay: 42595
    Fuzz.targetInterfaces() from: 0x0000000000000000000000000000000000030000 Time delay: 6 seconds Block delay: 4896
    Fuzz.fuzz_delegateCollateral(4369999,1524785991,88234109651709974343794513113785112769805635900493061281585349761168106275435,115792089237316195423570985008687907853269984665640564039457584007913129639933,0) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 32
    Fuzz.excludeContracts() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 46422
    Fuzz.fuzz_burnUSDFromSynthetix(4785833217208195328970646574223) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 5053
    Fuzz.fuzz_crashWETHPythPrice(25476845697035121763736771662605580125177619118584312647413036283710652449087) from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_guided_createDebt_LiquidateMarginOnly(false,1524785991) from: 0x0000000000000000000000000000000000010000
    Fuzz.fuzz_liquidateFlagged(209) from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 38100
    Fuzz.fuzz_pumpWBTCPythPrice(69019241900129816506093301311936514493300398317673844574145440550932985591986) from: 0x0000000000000000000000000000000000030000 Time delay: 3 seconds Block delay: 5140
    Fuzz.zeroOutMemory() from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 561
    Fuzz.fuzz_burnUSDFromSynthetix(34116435638630449540627727772912217272715670289207484923760363923548874852833) from: 0x0000000000000000000000000000000000010000
    Fuzz.targetArtifacts() from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 1088
    Fuzz.failed() from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 55538
    Fuzz.fuzz_liquidateFlagged(0) from: 0x0000000000000000000000000000000000010000
    Fuzz.zeroOutMemory() from: 0x0000000000000000000000000000000000010000
    Fuzz.fuzz_commitOrder(4370000,29569306801110173369255259629940846712699826178710513738506742790051962914851) from: 0x0000000000000000000000000000000000030000
    Fuzz.fuzz_cancelOrder(251) from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 45261
    Fuzz.IS_TEST() from: 0x0000000000000000000000000000000000030000
    Fuzz.fuzz_settleOrder() from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 14684
    Fuzz.repayDebt() from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 7278
    Fuzz.fuzz_guided_depositAndShort() from: 0x0000000000000000000000000000000000010000 Time delay: 4 seconds Block delay: 32767
    Fuzz.fuzz_guided_depositAndShortWBTC() from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 42229
    Fuzz.fuzz_delegateCollateral(216592120038409315430614080998136574909,301716905279369085090174297453791891502,1,1524785993,23942288908294858944485301061666975500641733209716141398976073325) from: 0x0000000000000000000000000000000000020000 Time delay: 3 seconds Block delay: 24311
    Fuzz.fuzz_changeOracleManagerPrice(1524785992,29754741601185319919143644719617558737820674580386367181806146663921552677524) from: 0x0000000000000000000000000000000000030000
    Fuzz.repayDebt() from: 0x0000000000000000000000000000000000010000
    Fuzz.repayDebt() from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 2526
    Fuzz.fuzz_changeWETHPythPrice(1524785993) from: 0x0000000000000000000000000000000000030000 Time delay: 1 seconds Block delay: 30011
    Fuzz.excludeContracts() from: 0x0000000000000000000000000000000000020000
    Fuzz.targetContracts() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 23403
    Fuzz.targetArtifactSelectors() from: 0x0000000000000000000000000000000000020000 Time delay: 6 seconds Block delay: 5140
    Fuzz.fuzz_guided_depositAndShort() from: 0x0000000000000000000000000000000000030000
    Fuzz.fuzz_cancelOrder(192) from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_changeWBTCPythPrice(1524785991) from: 0x0000000000000000000000000000000000030000
    Fuzz.targetContracts() from: 0x0000000000000000000000000000000000030000 Time delay: 2 seconds Block delay: 22699
    Fuzz.fuzz_crashWETHPythPrice(74445261737262899442454652605568939724013034985940359539458581551164502700472) from: 0x0000000000000000000000000000000000030000 Time delay: 5 seconds Block delay: 49415
    Fuzz.fuzz_liquidateFlagged(255) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 12338
    Fuzz.IS_TEST() from: 0x0000000000000000000000000000000000030000
    Fuzz.excludeContracts() from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 58783
    Fuzz.fuzz_pumpWBTCPythPrice(947) from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 5952
    Fuzz.fuzz_pumpWETHPythPrice(1524785991) from: 0x0000000000000000000000000000000000020000 Time delay: 5 seconds Block delay: 30784
    Fuzz.fuzz_pumpWETHPythPrice(113048627196545928106219217792339821532186373662277131369397273845930721288601) from: 0x0000000000000000000000000000000000020000
    Fuzz.fuzz_pumpWBTCPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639931) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 53562
    Fuzz.fuzz_liquidateMarginOnly() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 47075
    Fuzz.fuzz_liquidatePosition() from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 53349
    Fuzz.targetSelectors() from: 0x0000000000000000000000000000000000010000 Time delay: 5 seconds Block delay: 19933
    Fuzz.fuzz_pumpWBTCPythPrice(0) from: 0x0000000000000000000000000000000000030000 Time delay: 5 seconds Block delay: 38100
    Fuzz.fuzz_changeWETHPythPrice(1126350135) from: 0x0000000000000000000000000000000000020000 Time delay: 5 seconds Block delay: 24311
    Fuzz.fuzz_guided_depositAndShortWBTC() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 4223
    Fuzz.targetInterfaces() from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 1984
    Fuzz.fuzz_liquidateFlaggedAccounts(104) from: 0x0000000000000000000000000000000000030000
    Fuzz.fuzz_pumpWBTCPythPrice(1524785993) from: 0x0000000000000000000000000000000000010000 Time delay: 3 seconds Block delay: 45819
    Fuzz.targetSenders() from: 0x0000000000000000000000000000000000010000 Time delay: 1 seconds Block delay: 10992
    Fuzz.fuzz_changeWETHPythPrice(1524785993) from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 30784
    Fuzz.fuzz_liquidatePosition() from: 0x0000000000000000000000000000000000020000 Time delay: 1 seconds Block delay: 5054

"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)
