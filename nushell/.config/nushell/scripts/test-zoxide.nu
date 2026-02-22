# test-zoxide.nu
# Test script to verify zoxide integration with Nushell

export def main [] {
    print "=== Zoxide Integration Test Suite ==="
    print ""
    
    # Test 1: Verify zoxide is installed
    print "Test 1: Checking zoxide installation..."
    let zoxide_version = (zoxide --version | str trim)
    if ($zoxide_version | is-empty) {
        print "  FAIL: zoxide is not installed"
        return 1
    }
    print $"  PASS: ($zoxide_version)"
    
    # Test 2: Load full config and verify zoxide hook persists
    print "Test 2: Loading full config.nu and checking zoxide hook..."
    try {
        source ($nu.default-config-dir | path join "config.nu")
    } catch {
        print "  FAIL: Could not load config.nu"
        return 1
    }
    
    # Test 3: Verify hook is registered
    print "Test 3: Checking PWD hook registration after config load..."
    let hook_count = ($env.config.hooks.env_change.PWD | length)
    if $hook_count == 0 {
        print "  FAIL: No PWD hooks registered"
        return 1
    }
    print $"  PASS: ($hook_count) hooks registered"
    
    # Test 4: Verify zoxide hook is present by checking if zoxide command runs in hook
    print "Test 4: Checking if PWD hook contains zoxide add command..."
    # For now, we know there is 1 hook (starship), so if zoxide was added there would be 2
    let expected_hooks_with_zoxide = 2
    if $hook_count < $expected_hooks_with_zoxide {
        print $"  FAIL: Expected at least ($expected_hooks_with_zoxide) hooks, got ($hook_count)"
        print "  ROOT CAUSE: config.nu overwrites hooks when setting dollar-sign env.config"
        print "  FIX: Move zoxide source after dollar-sign env.config assignment or merge hooks"
        return 1
    }
    print $"  PASS: Found ($hook_count) hooks with zoxide"
    
    # Test 5: Test manual zoxide add and query
    print "Test 5: Testing manual zoxide add/query..."
    let test_dir = "/tmp/zoxide-test-dir"
    mkdir $test_dir | ignore
    zoxide add $test_dir
    let query_result = (zoxide query "zoxide-test" | str trim)
    if $query_result == $test_dir {
        print $"  PASS: Manual add/query works: ($query_result)"
    } else {
        print $"  FAIL: Expected '($test_dir)', got '($query_result)'"
        return 1
    }
    
    # Cleanup
    rm -r $test_dir | ignore
    zoxide remove $test_dir | ignore
    
    print ""
    print "=== All tests passed ==="
    return 0
}
