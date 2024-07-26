import re

def convert_to_solidity(call_sequence):
    # Regex patterns to extract the necessary parts
    call_pattern = re.compile(
    r'(?:Fuzz\.)?(\w+\([^\)]*\))(?: from: (0x[0-9a-fA-F]{40}))?(?: Gas: (\d+))?(?: Time delay: (\d+) seconds)?(?: Block delay: (\d+))?'
)
    wait_pattern = re.compile(r'\*wait\*(?: Time delay: (\d+) seconds)?(?: Block delay: (\d+))?')

    solidity_code = 'function test_replay() public {\n'

    lines = call_sequence.strip().split('\n')
    last_index = len(lines) - 1

    for i, line in enumerate(lines):
        call_match = call_pattern.search(line)
        wait_match = wait_pattern.search(line)
        if call_match:
            call, from_addr, gas, time_delay, block_delay = call_match.groups()
            
            # Add prank line if from address exists
            if from_addr:
                solidity_code += f'    vm.prank({from_addr});\n'
            
            # Add warp line if time delay exists
            if time_delay:
                solidity_code += f'    vm.warp(block.timestamp + {time_delay});\n'
            
            # Add roll line if block delay exists
            if block_delay:
                solidity_code += f'    vm.roll(block.number + {block_delay});\n'
            
            # Add function call
            if i < last_index:
                solidity_code += f'    try this.{call} {{}} catch {{}}\n'
            else:
                solidity_code += f'    {call};\n'
            solidity_code += '\n'
        elif wait_match:
            time_delay, block_delay = wait_match.groups()
            
            # Add warp line if time delay exists
            if time_delay:
                solidity_code += f'    vm.warp(block.timestamp + {time_delay});\n'
            
            # Add roll line if block delay exists
            if block_delay:
                solidity_code += f'    vm.roll(block.number + {block_delay});\n'
            solidity_code += '\n'

    solidity_code += '}\n'
    
    return solidity_code


# Example usage
call_sequence = """
Fuzz.fuzz_crashWBTCPythPrice(60368187887740273779520851036367321390742330372111243410017965485225816409222) Gas: 100000000 Time delay: 1 seconds Block delay: 43180
    Fuzz.targetInterfaces() Gas: 100000000 Time delay: 1 seconds Block delay: 59552
    Fuzz.fuzz_pumpWETHPythPrice(10400920) Gas: 100000000
    Fuzz.fuzz_settleOrder() Gas: 100000000
    Fuzz.failed() Gas: 100000000 Time delay: 1 seconds Block delay: 5952
    Fuzz.fuzz_liquidateFlaggedAccounts(54) Gas: 100000000
    Fuzz.fuzz_liquidateMarginOnly() Gas: 100000000 Time delay: 3 seconds Block delay: 590
    Fuzz.fuzz_modifyCollateral(7363886252298912951297268819470124426459998075572683640558215609191109221168,36060378883672883844) Gas: 100000000
    Fuzz.targetSenders() Gas: 100000000
    Fuzz.failed() Gas: 100000000 Time delay: 1 seconds Block delay: 32776
    Fuzz.repayDebt() Gas: 100000000
    Fuzz.pendingOrder(254864682208477713788650096748232259748) Gas: 100000000
    Fuzz.repayDebt() Gas: 100000000 Time delay: 5 seconds Block delay: 225
    Fuzz.fuzz_liquidateFlagged(16) Gas: 100000000
    Fuzz.fuzz_changeWETHPythPrice(1285495787) Gas: 100000000 Time delay: 1 seconds Block delay: 53349
    Fuzz.excludeContracts() Gas: 100000000
    Fuzz.fuzz_crashWBTCPythPrice(40734345885457213119587725476776602361710619297559342637786566930942934196174) Gas: 100000000 Time delay: 1 seconds Block delay: 49415
    Fuzz.collateralToMarketId(0xffffffff) Gas: 100000000 Time delay: 1 seconds Block delay: 35248
    Fuzz.fuzz_commitOrder(45527665955789711570906065755761038313,0) Gas: 100000000
    Fuzz.excludeSelectors() Gas: 100000000
    Fuzz.fuzz_changeWETHPythPrice(164129134689884637) Gas: 100000000 Time delay: 2 seconds Block delay: 38350
    Fuzz.targetSelectors() Gas: 100000000
    Fuzz.fuzz_changeWBTCPythPrice(703) Gas: 100000000
    Fuzz.fuzz_settleOrder() Gas: 100000000
    Fuzz.failed() Gas: 100000000 Time delay: 1 seconds Block delay: 23275
    Fuzz.IS_TEST() Gas: 100000000
    Fuzz.targetSenders() Gas: 100000000
    Fuzz.fuzz_settleOrder() Gas: 100000000
    Fuzz.fuzz_liquidatePosition() Gas: 100000000
    Fuzz.collateralToMarketId(0xffffffff) Gas: 100000000 Time delay: 1 seconds Block delay: 2512
    Fuzz.fuzz_burnUSDFromSynthetix(69440312566769276623656011396831292783790727085490337084095597749272364534186) Gas: 100000000 Time delay: 3 seconds Block delay: 59981
    Fuzz.fuzz_crashWBTCPythPrice(33474750363803198344703969225256527259022938577339749068987358902924311968844) Gas: 100000000
    Fuzz.fuzz_payDebt(328273681046912410412101207159872402337) Gas: 100000000
    Fuzz.fuzz_commitOrder(86168858261284524850319675772111529712,2423707) Gas: 100000000
    Fuzz.repayDebt() Gas: 100000000
    Fuzz.fuzz_modifyCollateral(15430920056894041623138793344739737515016944957914741277770872442158975318435,36060378883672883844) Gas: 100000000
    Fuzz.fuzz_modifyCollateral(15430920056894041623138793344739737515016944957914741277770872442158975318435,36060378883672883844) Gas: 100000000
    Fuzz.fuzz_crashWBTCPythPrice(104728133708937779018501638906324747851300398287592565595978335268451929896653) Gas: 100000000
    Fuzz.fuzz_pumpWETHPythPrice(256332019) Gas: 100000000 Time delay: 1 seconds Block delay: 45819
    Fuzz.fuzz_modifyCollateral(35,13161757840859343235923202888453968634670567318907731003551582133953012971661) Gas: 100000000
    Fuzz.fuzz_modifyCollateral(22866954023517326881472454420837192006879627097854062968841109005214028865838,21758050889834850033820492102659170992600571097412026316956767264376619351359) Gas: 100000000
    Fuzz.excludeArtifacts() Gas: 100000000 Time delay: 2 seconds Block delay: 31318
    Fuzz.fuzz_pumpWETHPythPrice(1524785992) Gas: 100000000
    Fuzz.targetInterfaces() Gas: 100000000 Time delay: 1 seconds Block delay: 15368
    Fuzz.fuzz_settleOrder() Gas: 100000000 Time delay: 1 seconds Block delay: 24311
    Fuzz.fuzz_changeOracleManagerPrice(0,7519350156025721105513033945595310101117735264990167366435493668905295328501) Gas: 100000000 Time delay: 1 seconds Block delay: 3708
    Fuzz.collateralToMarketId(0x0) Gas: 100000000
    Fuzz.fuzz_delegateCollateral(74925526633849638937062738874433663672,314018504,78785864899989875006334211634987353900540908220055761376259547605655821385692,27430329213400711167317844260663557624057715998269514346455789332778464393757,5948350862628443382883182303845845051077729108099372676306581706617715600343) Gas: 100000000
    Fuzz.targetSenders() Gas: 100000000 Time delay: 1 seconds Block delay: 4462
    Fuzz.failed() Gas: 100000000
    Fuzz.targetArtifacts() Gas: 100000000
    Fuzz.fuzz_pumpWBTCPythPrice(1524785993) Gas: 100000000 Time delay: 1 seconds Block delay: 27608
    Fuzz.fuzz_guided_createDebt_LiquidateMarginOnly(false,10254914090907667362931365709060444715882551265141187039062566737611087896158) Gas: 100000000
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)