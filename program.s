.section ".text.init"

# Memory-mapped I/O addresses
.equ BUTTON_BASE, 0x70000000
.equ LED_BASE,    0x50000000
.equ GAME_STATE,  0x90000000
.equ SP_BASE,     0x9FFFFFC0

# Register offsets for button controller
.equ BTN_SRC_OFF, 4
.equ BTN_PTM_OFF, 8
.equ BTN_STM_OFF, 12

.globl _start
_start:
    # Set up game value in memory
    li t0, GAME_STATE
    sw zero, 0(t0)     # Initialize game value to 0 (lose)
    
    # Set up interrupt vector
    lui t0, %hi(interrupt_handler)
    addi t0, t0, %lo(interrupt_handler)
    csrw mtvec, t0
    
    # TODO: Implement the rest of the setup for the interrupt handler
    csrrs t1, mstatus, 8
    li t0, 0x800
    csrrs t1, mie, t0

    la t0, BUTTON_BASE
    li t1, BTN_PTM_OFF
    add t1, t1, t0
    li t2, 0x55555
    sw t2, 0(t1)
    li t1, BTN_STM_OFF
    add t1, t1, t0
    li t2, 0x5555
    sw t2, 0(t1)
    
    li sp, SP_BASE

    li s1, LED_BASE
    
    # Long wait loop
    li t0, 5000  # Adjust this value to change the wait time
wait_loop:
    addi t0, t0, -1
    bnez t0, wait_loop
    
    # Load and check game result
    li t0, GAME_STATE
    lw t1, 0(t0)
    beqz t1, lose
    j win
    
lose:
    li t1, 0xFFFF01FF  # Set red LEDs on for all
    sw t1, 0(s1)
    j end_game
    
win:
    # Turn on green LEDs
    li t1, 0xFFFF02FF  # Set green LEDs on for all
    sw t1, 0(s1)
    
end_game:
    # Stop execution
    ebreak

interrupt_handler: # Interrupt handler
    addi sp, sp, -16
    sw s1, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)

    addi t0, zero, 1
    la t1, GAME_STATE
    sw t0, 0(t1)
    li t0, BTN_SRC_OFF
    la t1, BUTTON_BASE
    add t0, t0, t1
    sw zero, 0(t0)
    csrw mip, zero
    
    lw s1, 0(sp)
    lw t0, 4(sp)
    lw t1, 8(sp)
    lw t2, 12(sp)
    addi sp, sp, 16
    mret
