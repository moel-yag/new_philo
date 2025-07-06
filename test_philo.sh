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
NC='\033[0m' # No Color

# Time conversion functions
ms_to_seconds() {
    echo "scale=3; $1 / 1000" | bc
}

# =============================================
# Test Case 1: Single Philosopher
# =============================================
test_single_philosopher() {
    echo -e "${YELLOW}\nTEST 1: 1 800 200 200 (Single philosopher should die)${NC}"
    local args="1 800 200 200"
    local test_file="$TEST_DIR/single_philo.txt"
    local time_to_die=800
    
    # Run test with timeout (time_to_die + 100ms buffer)
    timeout $(ms_to_seconds $((time_to_die + 100))) $PHILO_EXEC $args > $test_file
    
    # Check results
    if grep -q "died" $test_file; then
        death_time=$(grep "died" $test_file | awk '{print $1}')
        if (( death_time >= time_to_die && death_time <= time_to_die + 10 )); then
            echo -e "${GREEN}PASSED: Philosopher died at ${death_time}ms (expected ~${time_to_die}ms)${NC}"
        else
            echo -e "${RED}FAILED: Death at ${death_time}ms, expected between ${time_to_die}-$((time_to_die+10))ms${NC}"
        fi
    else
        echo -e "${RED}FAILED: Philosopher should have died${NC}"
    fi
}

# =============================================
# Test Case 2: Five Philosophers (No death)
# =============================================
test_five_philosophers_no_death() {
    echo -e "${YELLOW}\nTEST 2: 5 800 200 200 (No philosopher should die)${NC}"
    local args="5 800 200 200"
    local test_file="$TEST_DIR/five_philo_no_death.txt"
    local timeout_sec=5  # 5 seconds
    
    # Run test
    timeout $timeout_sec $PHILO_EXEC $args > $test_file
    
    # Check results
    if grep -q "died" $test_file; then
        death_line=$(grep "died" $test_file)
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
    else
        echo -e "${GREEN}PASSED: No deaths occurred${NC}"
    fi
}

# =============================================
# Test Case 3: Five Philosophers with Meal Target
# =============================================
test_meal_target() {
    echo -e "${YELLOW}\nTEST 3: 5 800 200 200 7 (Stop after 7 meals each)${NC}"
    local args="5 800 200 200 7"
    local test_file="$TEST_DIR/meal_target.txt"
    
    # Calculate expected runtime (conservative estimate)
    local min_runtime=$((7 * (200 + 200) / 5))  # 560ms
    local max_runtime=$((7 * (200 + 200)))      # 2800ms
    
    # Run test
    start_time=$(date +%s.%N)
    $PHILO_EXEC $args > $test_file
    end_time=$(date +%s.%N)
    runtime=$(echo "$end_time - $start_time" | bc)
    runtime_ms=$(echo "$runtime * 1000" | bc | awk '{printf "%.0f", $1}')
    
    # Check results
    if grep -q "died" $test_file; then
        death_line=$(grep "died" $test_file)
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
        return
    fi
    
    # Count meals per philosopher
    declare -A meals
    for i in {1..5}; do
        meals[$i]=$(grep " $i is eating" $test_file | wc -l)
    done
    
    # Verify meal counts
    all_reached_target=true
    for i in {1..5}; do
        if [[ ${meals[$i]} -lt 7 ]]; then
            echo -e "${RED}FAILED: Philosopher $i ate only ${meals[$i]} times${NC}"
            all_reached_target=false
        fi
    done
    
    if $all_reached_target; then
        echo -e "${GREEN}PASSED: All philosophers ate at least 7 times (Runtime: ${runtime_ms}ms)${NC}"
    fi
}

# =============================================
# Test Case 4: Four Philosophers (No death)
# =============================================
test_four_philosophers_no_death() {
    echo -e "${YELLOW}\nTEST 4: 4 410 200 200 (No philosopher should die)${NC}"
    local args="4 410 200 200"
    local test_file="$TEST_DIR/four_philo_no_death.txt"
    local timeout_sec=5  # 5 seconds
    
    # Run test
    timeout $timeout_sec $PHILO_EXEC $args > $test_file
    
    # Check results
    if grep -q "died" $test_file; then
        death_line=$(grep "died" $test_file)
        echo -e "${RED}FAILED: Unexpected death - ${death_line}${NC}"
    else
        echo -e "${GREEN}PASSED: No deaths occurred${NC}"
    fi
}

# =============================================
# Test Case 5: Four Philosophers (One death)
# =============================================
test_four_philosophers_one_death() {
    echo -e "${YELLOW}\nTEST 5: 4 310 200 100 (One philosopher should die)${NC}"
    local args="4 310 200 100"
    local test_file="$TEST_DIR/four_philo_death.txt"
    local time_to_die=310
    
    # Run test
    timeout $(ms_to_seconds $((time_to_die + 200))) $PHILO_EXEC $args > $test_file
    
    # Check results
    death_count=$(grep -c "died" $test_file)
    if [[ $death_count -eq 0 ]]; then
        echo -e "${RED}FAILED: No philosopher died${NC}"
    elif [[ $death_count -gt 1 ]]; then
        echo -e "${RED}FAILED: Multiple deaths ($death_count) occurred${NC}"
    else
        death_line=$(grep "died" $test_file)
        death_time=$(echo "$death_line" | awk '{print $1}')
        if (( death_time >= time_to_die && death_time <= time_to_die + 10 )); then
            echo -e "${GREEN}PASSED: One philosopher died at ${death_time}ms (expected ~${time_to_die}ms)${NC}"
        else
            echo -e "${RED}FAILED: Death at ${death_time}ms, expected between ${time_to_die}-$((time_to_die+10))ms${NC}"
        fi
    fi
}

# =============================================
# Test Case 6: Two Philosophers Timing Accuracy
# =============================================
test_two_philosophers_timing() {
    echo -e "${YELLOW}\nTEST 6: 2 200 100 100 (Death within 10ms)${NC}"
    local args="2 200 100 100"
    local test_file="$TEST_DIR/two_philo_timing.txt"
    local time_to_die=200
    local max_delay=10
    local runs=10
    local passed=0
    
    echo "Running timing test $runs times..."
    
    for ((i=1; i<=$runs; i++)); do
        $PHILO_EXEC $args > $test_file
        if grep -q "died" $test_file; then
            death_time=$(grep "died" $test_file | awk '{print $1}')
            if (( death_time >= time_to_die && death_time <= time_to_die + max_delay )); then
                ((passed++))
            else
                echo "Run $i: Death at ${death_time}ms (expected ${time_to_die}-$((time_to_die+max_delay))ms"
            fi
        else
            echo "Run $i: No death occurred"
        fi
    done
    
    if [[ $passed -eq $runs ]]; then
        echo -e "${GREEN}PASSED: All $runs runs died within 10ms of ${time_to_die}ms${NC}"
    else
        echo -e "${RED}FAILED: Only $passed/$runs runs met timing requirements${NC}"
    fi
}

# =============================================
# Test Case 7: Random Tests
# =============================================
test_random_scenarios() {
    echo -e "${YELLOW}\nTEST 7: Random Test Scenarios${NC}"
    local tests=(
        "3 400 200 200"       # Should complete without death
        "2 300 150 150"       # Should complete without death
        "4 300 100 100"       # One might die
        "5 600 150 150 3"     # Meal target
    )
    
    for args in "${tests[@]}"; do
        echo -e "\nTesting: $args"
        local test_file="$TEST_DIR/random_${args// /_}.txt"
        local timeout_sec=5
        
        timeout $timeout_sec $PHILO_EXEC $args > $test_file
        
        if grep -q "died" $test_file; then
            death_line=$(grep "died" $test_file)
            death_time=$(echo "$death_line" | awk '{print $1}')
            philo_id=$(echo "$death_line" | awk '{print $2}')
            echo -e "  ${RED}DEATH: Philosopher $philo_id died at ${death_time}ms${NC}"
        else
            echo -e "  ${GREEN}No deaths occurred${NC}"
            
            # Check for meal target if specified
            if [[ $args == *" "*" "*" "*" "* ]]; then
                meal_target=$(echo $args | awk '{print $5}')
                for ((i=1; i<=$(echo $args | awk '{print $1}'); i++)); do
                    meals=$(grep " $i is eating" $test_file | wc -l)
                    if [[ $meals -lt $meal_target ]]; then
                        echo -e "  ${RED}FAILED: Philosopher $i ate only $meals times (target: $meal_target)${NC}"
                    else
                        echo -e "  ${GREEN}Philosopher $i reached target ($meal_target meals)${NC}"
                    fi
                done
            fi
        fi
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
test_random_scenarios

echo -e "\n${YELLOW}Testing complete. Results saved in $TEST_DIR${NC}"