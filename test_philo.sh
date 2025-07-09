#!/bin/bash

# =============================================
# Philosophers Project Testing Script
# =============================================

# Configuration
PHILO_EXEC="./philo"  # Path to your philo executable
TEST_DIR="./test_results"
mkdir -p $TEST_DIR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Time conversion functions
ms_to_seconds() {
    echo "scale=3; $1 / 1000" | bc
}

# =============================================
# Helper Functions
# =============================================

# Run program and capture output
run_test() {
    local args="$1"
    local test_file="$2"
    local timeout_val="$3"
    
    if [ -z "$timeout_val" ]; then
        $PHILO_EXEC $args > "$test_file" 2>&1
    else
        timeout $timeout_val $PHILO_EXEC $args > "$test_file" 2>&1
    fi
    return $?
}

# Clean timestamp values (remove newlines)
clean_timestamp() {
    echo "$1" | tr -d '\n'
}

# Check for thread issues in output
check_thread_issues() {
    local test_file="$1"
    if grep -i -q -e "error" -e "deadlock" -e "race" -e "timed out" "$test_file"; then
        echo -e "${RED}THREAD ISSUES DETECTED${NC}"
        grep -i -e "error" -e "deadlock" -e "race" -e "timed out" "$test_file" | head -3
        return 1
    fi
    return 0
}

# Check for overlapping output
check_output_overlap() {
    local test_file="$1"
    # Check if any line contains multiple messages
    if grep -q "[0-9] [0-9].*[0-9] [0-9]" "$test_file"; then
        echo -e "${RED}OVERLAPPING OUTPUT DETECTED${NC}"
        grep -m 1 "[0-9] [0-9].*[0-9] [0-9]" "$test_file"
        return 1
    fi
    return 0
}

# Run Valgrind memory check
run_valgrind() {
    local args="$1"
    local test_name="$2"
    local valgrind_log="$TEST_DIR/valgrind_${test_name}.log"
    
    echo -e "${BLUE}Running Valgrind for: $args${NC}"
    valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=42 \
             $PHILO_EXEC $args >/dev/null 2> "$valgrind_log"
    
    local valgrind_exit=$?
    if [ $valgrind_exit -eq 42 ]; then
        echo -e "${RED}MEMORY ISSUES DETECTED${NC}"
        grep -A 5 "ERROR SUMMARY" "$valgrind_log"
        return 1
    elif [ $valgrind_exit -ne 0 ]; then
        echo -e "${RED}VALGRIND ERROR (Exit code: $valgrind_exit)${NC}"
        return 2
    else
        echo -e "${GREEN}Valgrind clean${NC}"
        return 0
    fi
}

# =============================================
# Test Cases
# =============================================

# Test Case 1: Single Philosopher (Fixed)
test_single_philosopher() {
    echo -e "${YELLOW}\nTEST 1: 1 800 200 200 (Single philosopher should die)${NC}"
    local args="1 800 200 200"
    local test_file="$TEST_DIR/single_philo.txt"
    local time_to_die=800
    
    run_test "$args" "$test_file" "$(ms_to_seconds $((time_to_die + 100)))"
    
    cat "$test_file"
    # Check results
    if grep -q "died" "$test_file"; then
        # FIX: Properly clean and handle timestamp
        death_time=$(grep "died" "$test_file" | awk '{print $1}' | tr -d '\n')
        death_time_clean=$(clean_timestamp "$death_time")
        
        if [ -z "$death_time_clean" ]; then
            echo -e "${RED}FAILED: Could not extract death time${NC}"
        elif (( death_time_clean >= time_to_die && death_time_clean <= time_to_die + 10 )); then
            echo -e "${GREEN}PASSED: Philosopher died at ${death_time_clean}ms (expected ~${time_to_die}ms)${NC}"
        else
            echo -e "${RED}FAILED: Death at ${death_time_clean}ms, expected between ${time_to_die}-$((time_to_die+10))ms${NC}"
        fi
    else
        echo -e "${RED}FAILED: Philosopher should have died${NC}"
    fi
    
    check_thread_issues "$test_file"
    check_output_overlap "$test_file"
}

# Test Case 2: Five Philosophers (No death)
test_five_philosophers_no_death() {
    echo -e "${YELLOW}\nTEST 2: 5 800 200 200 (No philosopher should die)${NC}"
    local args="5 800 200 200"
    local test_file="$TEST_DIR/five_philo_no_death.txt"
    local timeout_sec=5
    
    run_test "$args" "$test_file" "$timeout_sec"
    
    # Check results
    if grep -q "died" "$test_file"; then
        death_line=$(grep "died" "$test_file")
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
    else
        echo -e "${GREEN}PASSED: No deaths occurred${NC}"
    fi
    
    check_thread_issues "$test_file"
    check_output_overlap "$test_file"
}

# Test Case 3: Five Philosophers with Meal Target
test_meal_target() {
    echo -e "${YELLOW}\nTEST 3: 5 800 200 200 7 (Stop after 7 meals each)${NC}"
    local args="5 800 200 200 7"
    local test_file="$TEST_DIR/meal_target.txt"
    
    # Run test
    start_time=$(date +%s.%N)
    run_test "$args" "$test_file" ""
    end_time=$(date +%s.%N)
    runtime=$(echo "$end_time - $start_time" | bc)
    runtime_ms=$(echo "$runtime * 1000" | bc | awk '{printf "%.0f", $1}')
    
    # Check results
    if grep -q "died" "$test_file"; then
        death_line=$(grep "died" "$test_file")
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
        return
    fi
    
    # Count meals per philosopher
    all_reached_target=true
    for i in {1..5}; do
        meals=$(grep " $i is eating" "$test_file" | wc -l)
        if [[ $meals -lt 7 ]]; then
            echo -e "${RED}FAILED: Philosopher $i ate only ${meals} times${NC}"
            all_reached_target=false
        else
            echo -e "Philosopher $i meals: ${meals}"
        fi
    done
    
    if $all_reached_target; then
        echo -e "${GREEN}PASSED: All philosophers ate at least 7 times (Runtime: ${runtime_ms}ms)${NC}"
    fi
    
    check_thread_issues "$test_file"
    check_output_overlap "$test_file"
}

# Test Case 4: Four Philosophers (No death)
test_four_philosophers_no_death() {
    echo -e "${YELLOW}\nTEST 4: 4 410 200 200 (No philosopher should die)${NC}"
    local args="4 410 200 200"
    local test_file="$TEST_DIR/four_philo_no_death.txt"
    local timeout_sec=5
    
    run_test "$args" "$test_file" "$timeout_sec"
    
    # Check results
    if grep -q "died" "$test_file"; then
        death_line=$(grep "died" "$test_file")
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
    else
        echo -e "${GREEN}PASSED: No deaths occurred${NC}"
    fi
    
    check_thread_issues "$test_file"
    check_output_overlap "$test_file"
}

# Test Case 5: Four Philosophers (One death)
test_four_philosophers_one_death() {
    echo -e "${YELLOW}\nTEST 5: 4 310 200 100 (One philosopher should die)${NC}"
    local args="4 310 200 100"
    local test_file="$TEST_DIR/four_philo_death.txt"
    local time_to_die=310
    
    run_test "$args" "$test_file" "$(ms_to_seconds $((time_to_die + 200)))"
    
    # Check results
    death_count=$(grep -c "died" "$test_file")
    if [[ $death_count -eq 0 ]]; then
        echo -e "${RED}FAILED: No philosopher died${NC}"
    elif [[ $death_count -gt 1 ]]; then
        echo -e "${RED}FAILED: Multiple deaths ($death_count) occurred${NC}"
    else
        death_line=$(grep "died" "$test_file")
        death_time=$(echo "$death_line" | awk '{print $1}')
        if (( death_time >= time_to_die && death_time <= time_to_die + 10 )); then
            echo -e "${GREEN}PASSED: One philosopher died at ${death_time}ms (expected ~${time_to_die}ms)${NC}"
        else
            echo -e "${RED}FAILED: Death at ${death_time}ms, expected between ${time_to_die}-$((time_to_die+10))ms${NC}"
        fi
    fi
    
    check_thread_issues "$test_file"
    check_output_overlap "$test_file"
}

# Test Case 6: Two Philosophers Timing Accuracy
test_two_philosophers_timing(){
    echo -e "${YELLOW}\nTEST 6: 2 200 100 100 (Timing accuracy test)${NC}"
    local args="2 200 100 100"
    local test_file="$TEST_DIR/two_philo_timing.txt"
    local timeout_sec=5
    
    run_test "$args" "$test_file" "$timeout_sec"
    
    # Check results
    if grep -q "died" "$test_file"; then
        death_line=$(grep "died" "$test_file")
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
    else
        echo -e "${GREEN}PASSED: No deaths occurred${NC}"
    fi
    
    check_thread_issues "$test_file"
    check_output_overlap "$test_file"
}

# Test Case 7: Error Cases
test_error_cases() {
    echo -e "${YELLOW}\nTEST 7: Error Case Testing${NC}"
    local tests=(
        "0 800 200 200"   # Invalid philosopher count
        "1 -800 200 200"  # Negative time
        "2 800 200"       # Too few arguments
        "2 800 200 200 100 200" # Too many arguments
        "abc 800 200 200" # Non-numeric argument
        "1 2147483648 200 200" # INT_MAX overflow
    )
    
    for args in "${tests[@]}"; do
        echo -e "\nTesting invalid arguments: $args"
        local test_file="$TEST_DIR/error_${args// /_}.txt"
        
        run_test "$args" "$test_file" ""
        
        # Check for expected non-zero exit code
        if [ $? -eq 0 ]; then
            echo -e "${RED}FAILED: Should return error for '$args'${NC}"
        else
            echo -e "${GREEN}PASSED: Correctly rejected invalid input${NC}"
        fi
        
        # Check for error messages
        if grep -qi "usage\|error" "$test_file"; then
            echo -e "  ${GREEN}Found error message${NC}"
        else
            echo -e "  ${RED}No error message found${NC}"
        fi
    done
}

# Test Case 8: Memory Leak Tests
test_memory_leaks() {
    echo -e "${YELLOW}\nTEST 8: Memory Leak Checks${NC}"
    local tests=(
        "1 800 200 200"           # Single philosopher
        "5 800 200 200"           # Standard case
        "4 410 200 200"           # Four philosophers
        "5 800 200 200 7"         # Meal target case
    )
    
    for args in "${tests[@]}"; do
        run_valgrind "$args" "${args// /_}"
    done
}

# Test Case 9: Large Input Test
test_large_input() {
    echo -e "${YELLOW}\nTEST 9: Large Input (200 philosophers)${NC}"
    local args="200 800 200 200"
    local test_file="$TEST_DIR/large_input.txt"
    local timeout_sec=15
    
    echo -e "${BLUE}Testing with 200 philosophers (timeout: ${timeout_sec}s)${NC}"
    
    start_time=$(date +%s.%N)
    run_test "$args" "$test_file" "$timeout_sec"
    end_time=$(date +%s.%N)
    runtime=$(echo "$end_time - $start_time" | bc)
    
    # Check results
    if grep -q "died" "$test_file"; then
        death_line=$(grep "died" "$test_file" | head -1)
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
    else
        echo -e "${GREEN}PASSED: No deaths occurred in large test${NC}"
        echo -e "Runtime: ${runtime} seconds"
    fi
    
    check_thread_issues "$test_file"
    check_output_overlap "$test_file"
}

# Test Case 10: Random Tests
test_random_scenarios() 
{
    echo -e "${YELLOW}\nTEST 10: Random Scenarios${NC}"
    local num_tests=5
    local max_philosophers=10
    local max_time=1000
    local max_meals=10
    
    for i in $(seq 1 $num_tests); do
        num_philosophers=$((RANDOM % max_philosophers + 1))
        time_to_die=$((RANDOM % max_time + 100))
        time_to_eat=$((RANDOM % (time_to_die / 2) + 50))
        time_to_sleep=$((RANDOM % (time_to_die / 2) + 50))
        meal_target=$((RANDOM % max_meals + 1))
        
        args="$num_philosophers $time_to_die $time_to_eat $time_to_sleep $meal_target"
        test_file="$TEST_DIR/random_test_${i}.txt"
        
        echo -e "\nRunning random test $i: $args"
        
        run_test "$args" "$test_file" ""
        
        # Check results
        if grep -q "died" "$test_file"; then
            death_line=$(grep "died" "$test_file")
            echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
        else
            echo -e "${GREEN}PASSED: No deaths occurred in random test $i${NC}"
        fi
        
        check_thread_issues "$test_file"
        check_output_overlap "$test_file"
    done
}

# =============================================
# Run All Tests
# =============================================
test_single_philosopher
test_five_philosophers_no_death
test_meal_target
test_four_philosophers_no_death
test_four_philosophers_one_death
test_two_philosophers_timing
test_error_cases
# test_memory_leaks
test_large_input
test_random_scenarios

echo -e "\n${YELLOW}Testing complete. Results saved in $TEST_DIR${NC}"
