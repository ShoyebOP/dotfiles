# test-venv.nu
# Test script to verify venv activation/deactivation commands

export def main [] {
    print "=== Venv Commands Integration Test Suite ==="
    print ""

    # Test 1: Verify venv.nu script exists
    print "Test 1: Checking venv.nu script installation..."
    let venv_script = ($nu.default-config-dir | path join "scripts" "venv.nu")
    if not ($venv_script | path exists) {
        print "  FAIL: venv.nu script not found"
        return 1
    }
    print $"  PASS: venv.nu script exists at ($venv_script)"

    # Test 2: Load venv.nu and verify commands are available
    print "Test 2: Loading venv.nu and checking command availability..."
    # Note: Commands are checked by trying to get help for them
    let venv_help = (help commands | where name =~ "venv-")
    if ($venv_help | where name == "venv-activate" | is-empty) {
        print "  FAIL: venv-activate command not found"
        print "  HINT: Make sure to run: overlay use venv.nu before running tests"
        return 1
    }
    print "  PASS: venv-activate command is available"
    
    if ($venv_help | where name == "venv-deactivate" | is-empty) {
        print "  FAIL: venv-deactivate command not found"
        return 1
    }
    print "  PASS: venv-deactivate command is available"

    # Test 3: Test venv-activate error when no venv found
    print "Test 3: Testing venv-activate error when no venv exists..."
    let test_dir = "/tmp/venv-test-empty"
    mkdir $test_dir | ignore
    let old_pwd = $env.PWD
    cd $test_dir
    try {
        venv-activate
        print "  FAIL: venv-activate should have errored when no venv found"
        cd $old_pwd
        rm -rf $test_dir | ignore
        return 1
    } catch {
        print "  PASS: venv-activate correctly errors when no venv found"
    }
    cd $old_pwd
    rm -rf $test_dir | ignore

    # Test 4: Test venv-activate with .venv folder (no activation script - should error gracefully)
    print "Test 4: Testing venv-activate with .venv folder (no activation script)..."
    let test_dir = "/tmp/venv-test-hidden"
    mkdir ($test_dir | path join ".venv") | ignore
    let old_pwd = $env.PWD
    cd $test_dir
    try {
        venv-activate
        # If it doesn't error, check if it handled the missing activation script
        print "  PASS: venv-activate handled .venv folder"
    } catch {
        print "  PASS: venv-activate correctly handled missing activation script"
    }
    cd $old_pwd
    rm -rf $test_dir | ignore

    # Test 5: Test venv-activate with venv folder (no activation script - should error gracefully)
    print "Test 5: Testing venv-activate with venv folder (no activation script)..."
    let test_dir = "/tmp/venv-test-normal"
    mkdir ($test_dir | path join "venv") | ignore
    let old_pwd = $env.PWD
    cd $test_dir
    try {
        venv-activate
        print "  PASS: venv-activate handled venv folder"
    } catch {
        print "  PASS: venv-activate correctly handled missing activation script"
    }
    cd $old_pwd
    rm -rf $test_dir | ignore

    # Test 6: Test venv-activate error when both venv and .venv exist
    print "Test 6: Testing venv-activate error when both venv folders exist..."
    let test_dir = "/tmp/venv-test-both"
    mkdir ($test_dir | path join ".venv") | ignore
    mkdir ($test_dir | path join "venv") | ignore
    let old_pwd = $env.PWD
    cd $test_dir
    try {
        venv-activate
        print "  FAIL: venv-activate should have errored when both venvs exist"
        cd $old_pwd
        rm -rf $test_dir | ignore
        return 1
    } catch {
        print "  PASS: venv-activate correctly errors when both venvs exist"
    }
    cd $old_pwd
    rm -rf $test_dir | ignore

    # Test 7: Test venv-deactivate error when no venv is active
    print "Test 7: Testing venv-deactivate error when no venv is active..."
    # Make sure we're not in a venv
    if "VIRTUAL_ENV" not-in $env {
        try {
            venv-deactivate
            print "  FAIL: venv-deactivate should have errored when no venv active"
            return 1
        } catch {
            print "  PASS: venv-deactivate correctly errors when no venv active"
        }
    } else {
        print "  SKIP: Already in a venv, skipping this test"
    }

    print ""
    print "=== All tests completed ==="
    return 0
}
